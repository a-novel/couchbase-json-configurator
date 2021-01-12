package credentials

import (
	"github.com/a-novel/errors"
	"strings"
)

func (c *Credentials) Verify() *errors.Error {
	if c.Username == "" {
		return errors.New(ErrNoUsernameFound, "missing cluster username")
	}

	if c.Password == "" {
		return errors.New(ErrNoPasswordFound, "missing cluster password")
	}

	if len(c.Username) > 128 {
		return errors.New(ErrUsernameTooLong, "username cannot contain more than 128 characters")
	}

	if strings.HasPrefix(c.Username, "@") {
		return errors.New(ErrUsernameForbiddenPrefix, "username cannot start with `@` character")
	}

	if strings.ContainsAny(c.Username, "()<>,;:\\\"/[]?={}") {
		return errors.New(
			ErrUsernameForbiddenCharacter,
			"username cannot contain any of the following characters : ( ) < > , ; : \\ \" / [ ] ? = { }",
		)
	}

	if len(c.Password) < 6 {
		return errors.New(
			ErrPasswordTooShort,
			"password should contain at least 6 characters",
		)
	}

	return nil
}
