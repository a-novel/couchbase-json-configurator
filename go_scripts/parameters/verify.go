package parameters

import "github.com/a-novel/errors"

func (p *Parameters) Verify() *errors.Error {
	if p.Timeout < 0 {
		return errors.New(ErrNegativeTimeout, "cannot set negative value for cluster timeout")
	}

	if p.Timeout == 0 {
		p.Timeout = 120
	}

	return nil
}
