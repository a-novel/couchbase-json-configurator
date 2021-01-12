package namespace

import (
	"fmt"
	"github.com/a-novel/divan-data-manager"
	"github.com/a-novel/divan-data-manager/types"
	"github.com/a-novel/errors"
)

func (n *Namespace) Check(username, password string) (*divan_types.NamespaceData, *errors.Error) {
	namespaces, err := divan_data_manager.GetNamespacesData(username, password, "")
	if err != nil {
		return nil, errors.New(
			ErrCannotFetchNamespacesInformation,
			fmt.Sprintf("unable to fetch namespaces information : %s", err.Error()),
		)
	}

	if output := divan_data_manager.FindNamespace(n.Name, namespaces); output != nil {
		return output, nil
	}

	return nil, errors.New(ErrCannotFindNamespaceData, fmt.Sprintf("cannot find namespace information for index %s", n.Name))
}
