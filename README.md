# Make relationships based on a pattern

1. [Overview](#overview)
1. [Usage](#usage)

## Overview

The `manifold` resource type allows you to make relationships on many other
resources at once. The relationships are generated at the end of the catalog
compilation, and they're generated based on simple pattern-matching on attributes.

You can specify any attribute to match, and you can specify either a string or
a regular expression. Unfortunately, this currently only works with native types,
so you can create relationships against all `package` resources tagged with 'internal'
but you cannot do the same for all `apache::vhost` defined resource types.

The pattern matching works like you might expect.

* If you're matching a **string** parameter:
    * and you pass a string, it matches using string equality.
    * and you pass a regex, if matches against the regex.
* If you're matching an **array** parameter:
    * and you pass a string, it uses string equality to check for membership in that array.
    * and you pass a regex, if uses regex to check for membership in that array.
* If you invert the match, the result of the above is inverted.
    * String/regex does *not* match.
    * String/regex doesn't match *any* array members.

This supports all standard relationships: `require`, `before`, `subscribe`, & `notify`.

## Usage

Example:

```puppet
manifold { 'internal':
  type         => 'package',
  match        => 'tag',
  pattern      => 'internal',  # or /internal/ to use a regular expression
  relationship => before,
}
package { ['foo', 'bar', 'baz']:
  ensure  => present,
  tag     => 'internal',
}
yumrepo { 'internal':
  ensure   => 'present',
  baseurl  => 'http://yum.example.com/el/7/products/x86_64/',
  descr    => 'Local packages',
  enabled  => '1',
  before   => Manifold['internal'],
}
```

- **invert**
    Invert the pattern matching.
Valid values are `true`, `false`.

- **match**
    The parameter name to match on

- **pattern**
    A string or regex pattern to match in combination with the match param

- **query**
    A hash of matches and patterns to use (unimplemented)

- **relationship**
    The relationship to enforce from this resource to the matched resources

- **type** (*namevar*)
    The type of other resource to depend upon
    
## TODO

* Allow relationships to be set on defined types.
* Allow more complex patterns to be used, such as matching multiple patterns.

## Disclaimer

I take no liability for the use of this module. It's in early stages of development.

Contact
-------

binford2k@gmail.com

