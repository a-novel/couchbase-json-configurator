# Divan Docker

Divan Docker is an overlay of the original [Couchbase Docker image](
https://hub.docker.com/_/couchbase?tab=description&page=1&ordering=last_updated
), adding an automated configuration script that handles the whole setup with a single json file input, delivering a 
ready-to-use and easily upgradable server instance.

```bash
docker pull kushuh/divan:latest
```

- [Start using Divan Docker](#start-using-divan-docker)
- [Create a config file](#create-a-config-file)
  - [Credentials](#credentials)
  - [Resources](#resources)
  - [Buckets](#buckets)
    - [Indexes](#indexes)
  - [Compaction](#compaction)
    - [Compaction Threshold (`threshold` and `viewThreshold`)](#compaction-threshold-threshold-and-viewthreshold)
    - [Compaction Timeframe (`from` and `to`)](#compaction-timeframe-from-and-to)
    - [Compaction abortOutside](#compaction-abortoutside)
  - [Parameters](#parameters)
- [Run your Docker image](#run-your-docker-image)
  - [Start from docker cli](#start-from-docker-cli)
  - [Start with docker-compose](#start-with-docker-compose)
  - [Update a running instance](#update-a-running-instance)
- [License](#license)

# Start using Divan Docker

Deploying a Couchbase cluster with Divan requires 2 simple steps, all detailed in the sections below.

- [Create a config file](#create-a-config-file).
- [Run your Docker image](#run-your-docker-image).

# Create a config file

- [Credentials](#credentials)
- [Resources](#resources)
- [Buckets](#buckets)
  - [Indexes](#indexes)
- [Compaction](#compaction)
  - [Compaction Threshold (`threshold` and `viewThreshold`)](#compaction-threshold-threshold-and-viewthreshold)
  - [Compaction Timeframe (`from` and `to`)](#compaction-timeframe-from-and-to)
  - [Compaction abortOutside](#compaction-abortoutside)
- [Parameters](#parameters)

Settings are done using a standard json file. The file has to be passed to the instance through binded volumes (more 
details in the [section about running Docker image]).

An example config can be shown below.

```json
{
  "credentials": {
    "username": "Administrator",
    "password": "password"
  },
  "resources": {
    "ramSize": 1024,
    "ftsRamSize": 2048,
    "indexRamSize": 1024
  },
  "buckets": {
    "users": {
      "ramSize": 256
    }
  }
}
```

A valid file only requires [credentials](#credentials) and [resources](#resources). Other fields are optional.

## Credentials

Both fields are required.

```json
{
  "credentials": {
    "username": "Administrator",
    "password": "password"
  }
}
```

Username should:
- contain less than 128 characters
- not start with `@`
- not contain any of the following characters: `( ) < > , ; : \ " / [ ] ? = { }`

Password should:
- contain at least 6 characters

## Resources

Only `purgeInterval` is optional.

```json
{
  "resources": {
    "ramSize": 1024,
    "ftsRamSize": 256,
    "indexRamSize": 256,
    "purgeInterval": 3.0
  }
}
```

Determine the amount of Ram (in Mb) to allocate to each services, plus the default interval in days for metadata purge.

| Key           | Required | Min  | Max  | Recommended value |
| :---          | :---     | :--- | :--- | :---              |
| ramSize       | true     | 256  | -    | -                 |
| indexRamSize  | true     | 256  | -    | -                 |
| ftsRamSize    | true     | 256  | -    | 2048 and above    |
| purgeInterval | -        | 0.04 | 60   | -                 |

from [Couchbase Server doc - Memory](https://docs.couchbase.com/server/current/learn/buckets-memory-and-storage/memory.html).

**ramSize**
- Allocated Ram for the [data service](https://docs.couchbase.com/server/current/learn/services-and-indexes/services/data-service.html).

**indexRamSize**
- Allocated Ram for the [index service](https://docs.couchbase.com/server/current/learn/services-and-indexes/services/index-service.html).

**ftsRamSize**
- Allocated Ram for the [full text search service](https://docs.couchbase.com/server/current/learn/services-and-indexes/services/search-service.html).

<hr>

**IMPORTANT NOTE FOR RESOURCES MANAGEMENT**

> By default, Couchbase Server allows 90% of a node’s total available memory to be allocated to the server and its
> services. Consequently, if a node’s total available memory is 100 GB, any attempt to allocate memory beyond 90 GB
> produces an error.

<hr>

## Buckets

- [Indexes](#indexes)

Each bucket should have a `ramSize` attribute. Ephemeral buckets also require `evictionPolicy` to be set.

Buckets are identified by keys, which represent their name. Each bucket should have a unique name across the cluster.
Bucket name should not be more than 100 characters long, and only contain `0-9A-Za-z` characters, in addition with `_`, 
`.`, `%` and `-`.

```json
{
  "buckets": {
    "users": {
      "ramSize": 256
    },
    "news": {
      "ramSize": 512,
      "type": "ephemeral",
      "evictionPolicy": "nruEviction",
      "flush": true
    }
  }
}
```

| Key            | Required              | Type   | Limits                                                                                                                |
| :---           | :---                  | :---   | :---                                                                                                                  |
| ramSize        | true                  | number | Min: 100<br/>Max: total amount of ramSize for all buckets should not exceed the amount defined in `resources.ramSize` |
| type           | -                     | string | `ephemeral` or `couchbase`, default value is `couchbase`                                                              |
| priority       | -                     | string | `low` or `high`                                                                                                       |
| evictionPolicy | for ephemeral buckets | string | Couchbase buckets: `valueOnly` or `fullEviction`<br/>Ephemeral buckets: `noEviction` or `nruEviction`                 |
| flush          | -                     | bool   |                                                                                                                       |
| purgeInterval  | -                     | float  | Couchbase buckets: between `0.04` and `60`<br/>Ephemeral buckets: between `0.007` and `60`                            |
| compaction     | -                     | object | See [Compaction section](#compaction) for more details                                                                |
| primaryIndex   | when indexes is setup | string | Should only contain `A-Za-z` characters, with addition of `#`, `-` and `_`, and start with a letter                   |
| indexes        | -                     | object | Couchbase buckets only, see [Indexes section](#indexes) for more details                                              |

**ramSize**
- The amount of Ram for your bucket data.

**type**
- [Bucket type](https://docs.couchbase.com/server/current/learn/buckets-memory-and-storage/buckets.html#bucket-types).

**priority**
- Priority of bucket background tasks.

**evictionPolicy**
- The memory-cache eviction policy for this bucket. \
  \
  Couchbase buckets support either "valueOnly" or "fullEviction". Specifying the "valueOnly" policy means that each key
  stored in this bucket must be kept in memory. This is the default policy: using this policy improves performance of
  key-value operations, but limits the maximum size of the bucket. Specifying the "fullEviction" policy means that 
  performance is impacted for key-value operations, but the maximum size of the bucket is unbounded. \
  \
  Ephemeral buckets support either "noEviction" or "nruEviction". Specifying "noEviction" means that the bucket will 
  not evict items from the cache if the cache is full: this type of eviction policy should be used for in-memory 
  database use-cases. Specifying "nruEviction" means that items not recently used will be evicted from memory, when all 
  memory in the bucket is used: this type of eviction policy should be used for caching use-cases.

**flush**
- Enable data flush for the bucket.

**purgeInterval**
- Sets the frequency of the tombstone (metadata) purge interval. Overrides global purgeInterval if set.

**compaction**
- Bucket level [compaction settings](#compaction). Overrides global compaction if set.

**primaryIndex**
- This is required to use secondary indexes. The primary index provides a default index for the index service, which is
  used to perform queries. Its name should be unique across the cluster, and also be unique across all secondary 
  indexes.
  
**secondary indexes**
- Create indexes based on an attribute within a document. The value associated with the attribute can be of any type: 
  scalar, object, or array. See [Indexes section](#indexes) for more details.
  
### Indexes

Couchbase Server indexes enhance the performance of query and search operations. An index declaration uses a list of
document keys to index.

> Index condition is not supported yet, since it is not implemented in the Go SDK the scripts rely on. It will be added
> to the 2.0 version coming in a few months - written in January 2021.

To use secondary indexes, a primary index must be setup on the bucket. An index can then simply be added. For example,
this bucket indexes each document by `author` and `genre` keys:

```json
{
  "buckets": {
    "books": {
      "primaryIndex": "books-primary-index",
      "indexes": {
        "books-author-and-genre-index": {
          "indexKey": ["author", "genre"]
        }
      },
      "ramSize": 1024
    }
  }
}
```

Each index name should be unique across the cluster and also across primary indexes, only contain `A-Za-z` characters,
with addition of `#`, `-` and `_`, and start with a letter.

More examples can be found at [Couchbase documentation](https://docs.couchbase.com/server/current/learn/services-and-indexes/indexes/indexing-and-query-perf.html).

## Compaction

- [Compaction Threshold (`threshold` and `viewThreshold`)](#compaction-threshold-threshold-and-viewthreshold)
- [Compaction Timeframe (`from` and `to`)](#compaction-timeframe-from-and-to)
- [Compaction abortOutside](#compaction-abortoutside)

Auto-Compaction settings determine the compaction process; whereby databases and their respective view-indexes are 
compacted.

This setting can either be declared on cluster level (top level), or per bucket. Is both global and bucket level
compaction are set, bucket level compaction will override the global compaction where it is set.

*example with global (top-level) compaction*

```json
{
  "compaction": {
    "parallelCompaction": true,
    "threshold": {
      "size": 1024,
      "percentage": 80
    },
    "viewThreshold": {
      "size": 256,
      "percentage": 90
    },
    "from": {
      "hour": 2
    },
    "to": {
      "hour": 6,
      "minute": 30
    },
    "abortOutside": true
  }
}
```

| Key                | Required                            | Type   |
| :---               | :---                                | :---   |
| parallelCompaction | -                                   | bool   |
| threshold          | [**(1)**](#compaction-annotation-1) | object |
| viewThreshold      | [**(1)**](#compaction-annotation-1) | object |
| from               | [**(2)**](#compaction-annotation-2) | object |
| to                 | [**(2)**](#compaction-annotation-2) | object |
| abortOutside       | -                                   | bool   |

<span id="compaction-annotation-1">**(1)**</span> At least one of both threshold should be set if a timeframe is given
(`from` and `to` keys).

<span id="compaction-annotation-2">**(2)**</span> A timeframe should be set (with at least 1 non zero parameter) if 
`abortOutside` flag is set to `true`.

### Compaction Threshold (`threshold` and `viewThreshold`)

A threshold value can be set with either one or both of the following:

| Key        | Type   | Limits                       |
| :---       | :---   | :---                         |
| size       | number | Greater than 1               |
| percentage | number | Between 2 and 100 (included) |

### Compaction Timeframe (`from` and `to`)

A timeframe can be set with either one or both of the following:

| Key    | Type   | Limits                      |
| :---   | :---   | :---                        |
| hour   | number | Between 0 and 23 (included) |
| minute | number | Between 0 and 59 (included) |

To be considered as valid, `to` and `from` values should be different, otherwise no error will be thrown, but no
timeframe will be setup.

### Compaction abortOutside

When a timeframe is set, allow compaction to continue outside the given timeframe if not finished in time.

## Parameters

An optional section to control the cluster setup.

```json
{
  "parameters": {
    "timeout": 120
  }
}
```

| Key     | Type   | Description                                    |
| :---    | :---   | :---                                           |
| timeout | number | timeout for setup operations, default is `120` |

# Run your Docker image

- [Start from docker cli](#start-from-docker-cli)
- [Start with docker-compose](#start-with-docker-compose)
- [Update a running instance](#update-a-running-instance)

Divan Docker has the same requirements as Couchbase Docker Image.

- As there are required for Couchbase operations and
  interaction, ports ranges `8091-8096` and `11210-11211` should be opened.
- Optional but highly recommended, a volume should be set to avoid data loss on cluster failure/rebooting.

Finally, you need to pass the config file through a shared volume. You can use one of the following methods to start
Divan Docker:

## Start from docker cli

Run the below command in any terminal, on a machine where **Docker is running**.

*optional: create a volume to save your data (replace `$VOLUME_NAME` with whatever you want)*
```bash
docker volume create $VOLUME_NAME
```
*replace `$CONTAINER_NAME` with whatever you want, `$CONFIG_PATH` with a path to your `config.json` file, and 
`$VOLUME_NAME` with the name of an existing volume*

```bash
docker run -d --name $CONTAINER_NAME \
-p '8091-8096:8091-8096' -p '11210-11211:11210-11211' \
--mount source=$VOLUME_NAME,target=/opt/couchbase/var \
--mount type=bind,source=$CONFIG_PATH,target=/root/DIVAN_config/config.json \
--env ENV=production \
kushuh/divan:latest
```

Or with no volumes:

```bash
docker run -d --name $CONTAINER_NAME \
-p '8091-8096:8091-8096' -p '11210-11211:11210-11211' \
--mount type=bind,source=$CONFIG_PATH,target=/root/DIVAN_config/config.json \
--env ENV=production \
kushuh/divan:latest
```

## Start with docker-compose

Write the following config in your `docker-compose.yml` file:

*replace `${CONFIG_PATH}` with a path to your `config.json` file, and `${VOLUME_NAME}` with the name of an existing 
volume*
```yaml
version: '3.9'
services:
  divan:
    image: kushuh/divan:latest
    ports:
      - '8091-8096:8091-8096'
      - '11210-11211:11210-11211'
    environment:
      - ENV=production
    volumes:
      - ${CONFIG_PATH}:/root/DIVAN-config/config.json
      - ${VOLUME_NAME}:/opt/couchbase/var

volumes:
  ${VOLUME_NAME}:
```

Then run your usual stuff.

> The current version DOES NOT support multi-nodes and thus won't work in swarm mode with size greater than 1. The
> multi-node support is not planned before 3.0.

## Update a running instance

Container does not update automatically when the config file is updated. Instead, you can rely on the below command
(change `$CONTAINER_NAME` by the name of your container):

```bash
docker exec "$CONTAINER_NAME" sh -c "cd /root/DIVAN_scripts && go run main.go"
```

# License
2020-2021, A-Novel [Apache 2.0 License](https://github.com/a-novel/divan-docker/blob/master/LICENSE).