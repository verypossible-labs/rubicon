# Rubicon

This project is part of [Very labs](https://github.com/verypossible-labs/docs/blob/master/README.md).
---

Rubicon is a device and framework used to test and provision Nerves devices. It
consists of three parts:

  * rubicon: A touchscreen device that is used for displaying testing and
    provisioning information to the operator. (This repo)
  * rubicon-api: The software framework used on the target to communicate with
    the rubicon.
  * rubicon-target: Testing firmware that is loaded on to the device being
    tested.

Rubicon is designed for flexibility. The intention is that the Rubicon device
is very generic and the Rubicon Target is very specific to your project.
The Rubicon device exposes a set of simple APIs that the Rubicon target can use
to perform all steps required for your project. An example of this could be:

  * Capture a barcode on the device
  * Test hardware functionality
  * Write production firmware to an eMMC
  * Provision an HSM

## Project goals

  * Connecting targets to Rubicon over multiple protocols
    * Ethernet
    * UART
    * SPI
  * Capture multiple barcodes
  * Print labels
  * Support multiple display sizes
  * Run arbitrary steps

Rubicon currently only supports communication over ethernet using Erlang
distribution.

# Building a Rubicon

To build a rubicon you will need the following components:

  * Raspberry Pi 3/B+
  * Raspberry Pi 7" Display
  * USB Drive (Data storage)
  * SmartiPi Touch Case (Optional)
  * Symbol (Motorola / Zebra) barcode scanner
    (Tested with the DS9208 and LS2208)

## Assemble the device

Follow the instructions at SmartiPi for detailed information on assembling the
device: https://smarticase.com/pages/smartipi-touch-2-setup-1

## Building the Rubicon firmware

For information on configuring your local development environment to use Nerves:
[Local Development](docs/local-development.md)

For information on building testing firmware, see [RubiconAPI](https://github.com/verypossible-labs/rubicon_api)

## Create a data drive

You will need a USB flash drive formatted FAT to store the target output
and to add any signer keys and installation firmware for the eMMC.
The following APIs require specific files to be placed on the drive

  * `signer_ssl`
    * `/signer-cert.pem` - The ATECC signer certificate.
    * `/signer-key.pem` - The ATECC signer private key.
  * `firmware_path`
    * `/install.fw` - The file to install onto the eMMC

## Managing Rubicon using NervesHub

Rubicon devices can be managed via NervesHub just like any Nerves device.
You can find more information about managing Nerves devices using NervesHub
from http://nerves-project.org/nerveshub or by viewing the docs at
https://docs.nerves-hub.org

To enable NervesHub in the Rubicon firmware, export the following environment
variables:

  NERVES_HUB_ENABLE=1
  NERVES_HUB_ORG=my_org_name
  FWUP_PUBLIC_KEYS="<fwup_public_key>,<fwup_public_key>"

# Using rubicon

Create the firmware, burn it to an SD card, and insert it into the raspberry pi.
Next, connect the USB drive and the USB barcode scanner to the Rubicon device
and apply power.

Once it boots, you should see a main screen that says `Scan a board to begin`.
