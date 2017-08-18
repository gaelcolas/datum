# The object dot notation resolving to a path

This demo shows how I resolve a call to subproperties of an $Node object, into the path.

The object `$Node` object does not have properties under `$Node.Roles`, but any call to its subproperties resolve to a path, using the `.` as delimiter:
from :
`$Node.Roles.My.Path.Here`
returns the path:
`My\Path\Here`


The ultimate goal of this proof of concept, is to allow the User to do a Property lookup in the Hierarchical data stores while using a common and well known way that seems to be a Nodes sub property.

I also Intend to allow a 'dump' of all properties under the `$Node` for troubleshooting, but I haven't written that function yet (more recursivity! Yay!).