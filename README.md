# Borneol

Borneol is an tool used to test and provision devices at the end of the
manufacturing line. The project is split into three parts:

`borneol_host` - The firmware for the touch screen device used to interact with
the manufacturer.

`borneol_api` - A shared dependency that is used by a `borneol_target` to
interact with the `borneol_host`.

`borneol_target` - An example firmware that uses the `borneol_api` to run
tests and provision the device.
