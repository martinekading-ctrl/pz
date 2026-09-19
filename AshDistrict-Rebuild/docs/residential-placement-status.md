# Residential placement pass

Eight previously empty residential plots now instantiate six catalog floor plans.
Existing B01 remains unchanged. All new homes have meter-based footprints, room walls,
an operable front door, searchable starter furnishings, and a path to an existing street.

| Instance | Plan | Origin (map cells) |
| --- | --- | --- |
| R02 | H01 | 92,128 |
| R03 | H02 | 143,126 |
| R04 | H05 | 165,193 |
| R05 | H03 | 167,237 |
| R06 | H06 | 141,307 |
| R07 | H04 | 64,306 |
| R08 | H02 | 47,232 |
| R09 | H01 | 52,183 |

Generate placement data with tools/build_residential_catalog.py. This updates only the
catalog placement file, plot sizes, and named house access paths. Existing roads are retained.
Preview with --catalog-preview; F6 cycles homes as a debug shortcut, not a gameplay transition.

Validation: --standard-test passed entrance-to-search-zone checks for all 11 interactive
buildings (including the eight additions). Native --catalog-capture produces exterior/interior
frames for each new home. Furniture behind solid room walls is hidden by logical line of sight.

Remaining art work: the six layouts share the existing gable roof and siding asset family;
the catalog's hip roof, farm porch, and independent garage exterior door are not implemented.
Starter furniture does not yet constitute a fully furnished house. This is a playable placement
pass, not final visual acceptance of the six house designs.
