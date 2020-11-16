# Divan for Docker

Divan is a wrapper for the original [Couchbase Docker image](https://hub.docker.com/_/couchbase). It provides automated
setup and upgrade for your cluster through an easy to configure json file.

If it is your first time using Divan, we recommend you to visit [this section](#divan-philosophy) before going further, 
to ensure it will match your needs and use case.

- [Setup Divan](#setup-divan)
    - [Physical resources](#physical-resources)
        - [Deployment](#development)
        - [Production](#production)
        - [Docker limitation](#docker-limitation)
    - [Docker compose](#docker-compose)
    - [Securing your cluster](#securing-your-cluster)
    - [Production securities](#production-securities)
    - [Warning about running Divan with Swarm mode](#warning-about-running-divan-with-swarm-mode)
- [Configuration](#configuration)
    - [Available options](#available-options)
        - [Credentials](#credentials)
        - [Resources](#resources)
            - [About automatic allocation](#about-automatic-allocation)
            - [About purge interval](#about-purge-interval)
        - [Compaction](#compaction)
            - [Compaction Threshold](#compaction-threshold)
            - [Compaction parallelCompaction](#compaction-parallelcompaction)
            - [Compaction Timeframe](#compaction-timeframe)
            - [Compaction abortOutside](#compaction-abortoutside)
        - [Buckets](#buckets)
            - [Available options](#available-options-bucket)
- [Divan philosophy](#divan-philosophy)
    - [Why Divan](#why-divan)
    - [When to use](#when-to-use)
    - [Cut Couchbase options](#cut-couchbase-options)
- [Testing](#testing)
    - [Recommended resources for testing](#recommended-resources-for-testing)
- [License](#license)

# Setup Divan

## Physical resources

### Development

Couchbase is a demanding system when it comes to RAM. They provide a nice [documentation about system requirements](
https://docs.couchbase.com/server/current/install/pre-install.html
).

### Production

You are going to allocate a certain amount of Ram through your configuration file. Please be aware that Couchbase
doesn't allow your cluster to [reserve more than 90% of the total available RAM](
https://docs.couchbase.com/server/current/learn/buckets-memory-and-storage/memory.html
).

If you build your container with 4096Mb of RAM, your container will need to dispose at least ~4600Mb of RAM. It is
especially important when you upgrade your cluster with more RAM, to ensure your server have enough free resources
to handle the charge.

### Docker limitation

On some systems, Docker daemon is configured to limit the amount of resources a container can claim. If despite having
physical resources that matches your needs, you get a "not enough RAM"" error, you need to dig into your docker 
preferences to change this setting.

## Docker compose

For development, the minimal configuration for Divan to run is given below:

```yaml
version: '3.8'
services:
  db:
    image: kushuh/divan:1.0.0
    # Ports required by Couchbase.
    ports:
      - '8091-8096:8091-8096'
      - '11210-11211:11210-11211'
    volumes:
      # Folder where all your config files go.
      - /path/to/config_folder:/root/DIVAN-config
```

Your config folder contains your config.json file, with an optional secret.json file that is recommended in production
environments.

> It is required your files are named `config.json` and `secret.json`, otherwise deployment will fail.

## Securing your cluster

```yaml
version: '3.8'
services:
  db:
    image: kushuh/divan:1.0.0
    # Ports required by Couchbase.
    ports:
      - '8091-8096:8091-8096'
      - '11210-11211:11210-11211'
    environment:
      # Run your deploy command with ENV=production.
      # Read more at the below section, to see what security settings are added for your 
      # production deployments.
      - ENV=${ENV}
    volumes:
      # Using ENV variables for configuration location will make your configuration more flexible.
      - ${ENV_PATH_TO_CONFIG_FOLDER}:/root/DIVAN-config
      # Save your buckets data to keep it consistent across deployments.
      - db:/opt/couchbase/var

volumes:
  db:
```

> It is recommended you put your environment variable in a .env file, within the docker-compose directory.

## Production securities

When using environment variables to set the running environment, Divan will add some protection against data loss.

> Divan will recognize a development environment if the ENV variable is either empty or equal to `development`. Any
> other value will be considered as a critical environment, and thus apply security.

Those protections will ensure no bucket will be deleted. In development mode, a bucket is deleted when it is either
removed from configuration, or when an option marked as "non upgradable" is changed.

If either one of those scenarios occurs in production, the cluster will not be updated, and an error message will be
returned.

If you still want to perform an operation that requires removing a bucket in production mode, you'll have to log in to 
the UI manually *(`http://YOUR_SERVER_IP:8091`, make sure 8091 port is opened on your server)*. Then, delete your bucket
from the UI and re-run the deployment with your new configuration.

> Divan will perform a deep check of your configuration before running it. While it might have a little impact on
> deployment performances, it ensures no operation will run with non correct parameters.

## Warning about running Divan with Swarm mode

Deploying multi-nodes clusters with docker swarm may work but is untested for now. As a consequence, multi-nodes
specific options are not yet available.

Read more at the [cut features](#cut-couchbase-options) section.

# Configuration

Divan automatically perform the setup you usually do through UI or cli, by allowing you to pass a single .json for the
entire setup.

```json5
{
  "database": {
    // config goes here.
  }
}
```

## Available options

| Key | Type | Required | Upgradable |
| :--- | :--- | :--- | :--- |
| [username](#credentials) | string | :white_check_mark: <br/>*can be omitted if a secret key is given* | :white_check_mark: |
| [password](#credentials) | string | :white_check_mark: <br/>*can be omitted if a secret key is given* | :white_check_mark: |
| [resources.ramSize](#resources) | number | :white_check_mark: <br/>*can be omitted if automatic allocation is set with valid parameters* | :white_check_mark: |
| [resources.ftsRamSize](#resources) | number | :white_check_mark: | :white_check_mark: |
| [resources.indexRamSize](#resources) | number | :white_check_mark: | :white_check_mark: |
| [resources.purgeInterval](#resources) | number | :x: | :white_check_mark: |
| [resources.compaction](#compaction) | Compaction config | :x: | :white_check_mark: |
| [resources.buckets](#buckets) | JSON | :x: | :white_check_mark: |
| [resources.buckets[name]](#buckets) | string | :white_check_mark: | :x:<br/>*Changing a bucket name will result in the creation of a new one* |
| [resources.buckets[].ramSize](#buckets) | number | :white_check_mark: | :white_check_mark: |
| [resources.buckets[].type](#buckets) | string | :x:<br/>*will use couchbase as default value* | :x: |
| [resources.buckets[].priority](#buckets) | string | :x: | :white_check_mark: |
| [resources.buckets[].evictionPolicy](#buckets) | string | :x: | :white_check_mark: for couchbase buckets<br/>:x: for ephemeral buckets |
| [resources.buckets[].flush](#buckets) | boolean | :x: | :white_check_mark: |
| [resources.buckets[].purgeInterval](#buckets) | number | :x: | :white_check_mark: |
| [resources.buckets[].compaction](#compaction) | Compaction config | :x: | :white_check_mark: |

### Credentials

Credentials for the cluster administrator user.

```json
{
  "database": {
    "username": "Administrator",
    "password": "password"
  }
}
```

Note that, although those credentials can be hardcoded into the config file, it is recommended to set them in a
separate file that will not be pushed to a git repository.

A secret credentials file is in json format:

```json
{
  "username": "Secret_Administrator",
  "password": "Secret_Password"
}
```

You can put this secret file in your config folder on the remote host.

> If credentials are given along with a secret env key, Divan will first look for credentials within the secret file, 
> and fallback on the configuration file keys if secret file is invalid or some keys are missing.

Note the following restrictions apply to credentials:

Username should:
- contain less than 128 characters
- not start with `@`
- not contain any of the following characters: `( ) < > , ; : \ " / [ ] ? = { }`

Password should:
- contain at least 6 characters

### Resources

```json
{
  "database": {
    "resources": {
      "ramSize": 2048,
      "ftsRamSize": 2048,
      "indexRamSize": 1024,
      "purgeInterval": 3
    }
  }
}
```

Resources values are declared with a number representing a RAM amount in Mb (with the exception of purgeInterval, which
represents a decimal day value).

<hr>

**IMPORTANT NOTE FOR RESOURCES MANAGEMENT**

> By default, Couchbase Server allows 90% of a node’s total available memory to be allocated to the server and its 
> services. Consequently, if a node’s total available memory is 100 GB, any attempt to allocate memory beyond 90 GB 
> produces an error.

Considering the following config:

```json
{
  "database": {
    "resources": {
      "ramSize": 2048,
      "ftsRamSize": 2048,
      "indexRamSize": 1024
    }
  }
}
```

Couchbase Server will actually need `(2048 + 2048 + 1024) * 100/90` Mb of RAM, which roughly approximates to 5700Mb of 
allocatable RAM.

More about it here: https://docs.couchbase.com/server/current/learn/buckets-memory-and-storage/memory.html

<hr>

Note the following restrictions apply to resources:

From https://docs.couchbase.com/server/current/install/sizing-general.html#about-couchbase-server-resources.

ramSize should be at least `1024`. \
indexRamSize should be at least `256`. \
ftsRamSize should be at least `256` *(`2048` and above recommended)*.

Also note that purgeInterval, as defined globally for couchbase clusters, should be a number between `0.04` and `60`.

#### About automatic allocation

`ramSize` value can be omitted if the Cluster is eligible for automatic allocation. Basically, if the script do not 
detect any ramSize value, it will calculate the total amount of RAM required by the buckets, and use it to configure 
data service. This ensure that an optimal amount of RAM is allocated.

This method makes it easy to add more buckets, however be aware of the following pitfalls:
- Total amount of requested RAM has to match the ramSize requirements in the 
Restriction section above.

#### About purge interval

https://docs.couchbase.com/server/current/manage/manage-settings/configure-compact-settings.html#tombstone-purge-interval

Sets the frequency of the metadata (or tombstone) purge interval, for Couchbase buckets only.

### Compaction

Auto-Compaction settings determine the compaction process; whereby databases and their respective view-indexes are 
compacted.

More at https://docs.couchbase.com/server/current/manage/manage-settings/configure-compact-settings.html.

Compaction supports following keys:

| Key | Type | Required | Upgradable |
| :--- | :--- | :--- | :--- |
| [parallelCompaction](#compaction-parallelcompaction) | boolean | :x: | :white_check_mark: |
| [threshold.percentage](#compaction-threshold) | number | :x: | :white_check_mark: |
| [threshold.size](#compaction-threshold) | number | :x: | :white_check_mark: |
| [viewThreshold.percentage](#compaction-threshold) | number | :x: | :white_check_mark: |
| [viewThreshold.size](#compaction-threshold) | number | :x: | :white_check_mark: |
| [from.hour](#compaction-timeframe) | number | :x: | :white_check_mark: |
| [from.minute](#compaction-timeframe) | number | :x: | :white_check_mark: |
| [to.hour](#compaction-timeframe) | number | :x: | :white_check_mark: |
| [to.minute](#compaction-timeframe) | number | :x: | :white_check_mark: |
| [abortOutside](#compaction-abortoutside) | boolean | :x: | :white_check_mark: |

#### Compaction Threshold

Sets the database or fragmentation trigger threshold.

A threshold object has 2 optional keys:

```json
{
  "threshold": {
    "percentage": 75,
    "size": 1024
  },
  "viewThreshold": {
    "percentage": 50,
    "size": 512
  }
}
```

- Percentage is relative to the total amount of RAM available for the bucket. It has
 to be a number between `2` and `100`.
- Size is an absolute RAM value. It has to be a number greater than or equal to `1`.

#### Compaction parallelCompaction

Run index and data compaction in parallel. It is optional and defaults to `false`.

#### Compaction Timeframe

You can optionally give a timeframe for compaction to happen. To set a timeframe, 
you **need to have at least one threshold set**.

```json
{
  "from": {
    "hour": 2,
    "minute": 0
  },
  "to": {
    "hour": 6,
    "minute": 0
  }
}
```

Note that if you set a timeframe, you should set every timeframe parameter
explicitly, or the command will fail.

- Hour should be a number between `0` and `23`.
- Minute should be a number between `0` and `59`.

#### Compaction abortOutside

Will set the option that terminate compaction if the process takes longer than the
allowed time. This parameter requires a valid [timeframe](#compaction-timeframe) to
be set.

### Buckets

Add buckets to your cluster automatically.

```json 
{
  "database": {
    "resources": {
      "buckets": {
        "users": {
          "ramSize": 256
        },
        "posts": {
          "ramSize": 1024,
          "evictionPolicy": "fullEviction"
        }
      }
    }
  }
}
```

<h4 id="available-options-bucket">Available options</h4>

| Key | Type | Required | Upgradable |
| :--- | :--- | :--- | :--- |
| [resources.buckets[name]](#buckets) | string | :white_check_mark: | :x:<br/>*Changing a bucket name will result in the creation of a new one* |
| [resources.buckets[].ramSize](#buckets) | number | :white_check_mark: | :white_check_mark: |
| [resources.buckets[].type](#buckets) | string | :x:<br/>*will use couchbase as default value* | :x: |
| [resources.buckets[].priority](#buckets) | string | :x: | :white_check_mark: |
| [resources.buckets[].evictionPolicy](#buckets) | string | :x: | :white_check_mark: for couchbase buckets<br/>:x: for ephemeral buckets |
| [resources.buckets[].flush](#buckets) | boolean | :x: | :white_check_mark: |
| [resources.buckets[].purgeInterval](#buckets) | number | :x: | :white_check_mark: |
| [resources.buckets[].compaction](#compaction) | Compaction config | :x: | :white_check_mark: |

Following restrictions apply to bucket options:

- **name**
    - it is unique across the cluster.
    - it doesn't contain more than 100 characters.
    - it only contains alphanumeric characters `A-Za-z0-9`, with the addition of `_` `.` `%` `-`.
- **ramSize**
    - `100` or above.
- **type**
    - either `couchbase` or `ephemeral`, default value is `couchbase`.
- **priority**
    - either `low` or `high`, default value is `low`.
- **evictionPolicy**
    - **Couchbase bucket** : either `valueOnly` or `fullEviction`, default value is `valueOnly`.
    - **Ephemeral bucket** : either `noEviction` or `nruEviction`, default value is `noEviction`.
- **flush**
    - should be a boolean.
- **purgeInterval**
    - **Couchbase bucket** : number between `0.04` and `60`.
    - **Ephemeral bucket** : number between `0.007` and `60`.
    > Number is in days. `0.04` represents an hour, while `0.007` is approximately a minute.
- **compaction**
    - bucket level compaction settings. Should comply with restrictions of above [Compaction](#compaction) section.
    > This option is available for `couchbase` buckets only.

You can learn more about each option at [Couchbase documentation](
https://docs.couchbase.com/server/current/cli/cbcli/couchbase-cli-bucket-create.html).

# Divan philosophy

## Why Divan

Divan for Docker came from the need to heavily automate Couchbase deployments on small scale situations, for both
time and stability.

Divan for Docker is made to run on single instance servers, with the attempt to make it compatible with multi purposes
VMs. Thus, if you are a small company that wants to run all of its services on a unique remote host, you can do it
easily with Divan.

Divan for Docker is made to be super easy to configure, with a one-step configuration and strong check-up, to avoid
errors and tell you what is wrong in a human, comprehensive way.

## When to use

###### DO NOT USE

If you are a large organization with money and huge system requirements, then you should go for the official 
[Autonomous Operator](https://docs.couchbase.com/operator/current/overview.html). It has everything you need for 
security and reliability concerns, and provides advanced and exclusive features that are absent from Divan for Docker.

###### USE

If you are a small scale organization or startup, that doesn't require multi-cluster database, or if you are deploying 
a full application on a single instance. Divan for Docker will run your database in an isolated container, so you can 
safely deploy this image on multi-purposes VMs.

## Cut Couchbase options

As it is intended for small scale organisations, Divan relies on the community edition of Couchbase Server. Thus,
**Entreprise editon features are unavailable**.

Divan **does not currently provides support for multi node clusters**. They are hard to test features, since both Couchbase
CLI and REST Api comes with multiple inconsistencies that requires deep testing, to ensure stability of the container.

Finally, only **one couchbase cluster can be deployed per physical machine**. This is another limitation that may be
implemented in the future.

# Testing

This util is tested using [bats](https://github.com/bats-core/bats-core) and
[jq](https://github.com/stedolan/jq).
To run tests, cd into the repo folder and enter :

```shell script
$ sh tests/_test.sh
```

## Recommended resources for testing

Test suite requires your Docker daemon to allow at least 6Gb or Ram per container. It is recommended your computer have
at least 16Gb of Ram.

# License
2020, A-Novel [Apache 2.0 License](https://github.com/a-novel/divan-docker/blob/master/LICENSE).