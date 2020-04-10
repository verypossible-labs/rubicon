# Rubicon

Rubicon is an tool used to test and provision devices at the end of the
manufacturing line. The project is split into three parts:

`rubicon_host` - The firmware for the touch screen device used to interact with
the manufacturer.

`rubicon_api` - A shared dependency that is used by a `rubicon_target` to
interact with the `rubicon_host`.

`rubicon_target` - An example firmware that uses the `rubicon_api` to run
tests and provision the device.
