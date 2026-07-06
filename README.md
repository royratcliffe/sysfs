# sysfs

SWI-Prolog helpers for reading and writing Linux sysfs entries, with focused support for GPIO and PWM class devices.

This pack wraps common sysfs operations as Prolog predicates so you can:

- discover GPIO and PWM chips,
- export and unexport lines/channels,
- read and write typed values (numbers, atoms, bytes, endian-encoded words),
- bridge PWM chips back to their GPIO providers using device-tree phandles.

## Requirements

- Linux with sysfs mounted at `/sys`
- SWI-Prolog 9.x
- permissions to read/write the target sysfs nodes (often root or udev rules)

## Install

From SWI-Prolog:

```prolog
?- pack_install('https://github.com/royratcliffe/sysfs.git').
```

Or clone and use locally.

## What Is Included

- `prolog/sysfs/sysfs.pl`
  - sysfs root/class discovery and exported-file retry support.
- `prolog/sysfs/read_file.pl`
  - typed readers: `term`, `bytes`, `number`, `atom`, `line`, `lines`, `big/little` endian forms.
- `prolog/sysfs/write_file.pl`
  - typed writers matching the read-side formats.
- `prolog/sysfs/gpiochip.pl`
  - discover/read GPIO chip metadata (`base`, `ngpio`, `label`, `phandle`).
- `prolog/sysfs/gpio.pl`
  - export, unexport, ensure, read, and write GPIO line files.
- `prolog/sysfs/pwmchip.pl`
  - discover/read PWM chip metadata (`npwm`, `device/name`, `device/of_node/gpios`).
- `prolog/sysfs/pwm.pl`
  - export, unexport, ensure, read, and write PWM channel files.
- `prolog/sysfs/phandles.pl`
  - map PWM chips to GPIO chip + offset via device-tree phandles.

## Quick Start

### Load modules

```prolog
:- use_module(library(sysfs/gpiochip)).
:- use_module(library(sysfs/gpio)).
:- use_module(library(sysfs/pwmchip)).
:- use_module(library(sysfs/pwm)).
```

If running from this repository checkout directly, adjust load paths as needed.

### List GPIO chips and labels

```prolog
?- sysfs_gpiochip_read(label, Chip, Label).
Chip = gpiochip570,
Label = 'raspberrypi-exp-gpio' ;
...
```

### Export and control one GPIO line

```prolog
?- sysfs_gpio_ensure_exported(gpiochip512, 14, Export, Line).
Export = 526,
Line = gpio526.

?- sysfs_gpio_write(direction, gpiochip512, 14, out).
true.

?- sysfs_gpio_write(value, gpiochip512, 14, 1).
true.

?- sysfs_gpio_read(value, gpiochip512, 14, V).
V = 1.
```

### Configure PWM channel 0

```prolog
?- sysfs_pwmchip_read(npwm, Chip, N).
Chip = pwmchip0,
N = 4 ;
...

?- sysfs_pwm_ensure_exported(pwmchip0, 0, Chan).
Chan = pwm0.

?- sysfs_pwm_write(period, pwmchip0, 0, 20000000).
true.

?- sysfs_pwm_write(duty_cycle, pwmchip0, 0, 1500000).
true.

?- sysfs_pwm_write(enable, pwmchip0, 0, 1).
true.
```

## Typed File I/O

`read_file_as/3` and `write_file_as/3` support several formats:

- as a `term`
- as `bytes`
- as a `number`
- as an `atom`
- as a `line`
- as `lines`
- as `big(Width)`, or `bigs(Width)`
- as `little(Width)`, or `littles(Width)`

Example:

```prolog
?- read_file_as(big(32), '/sys/class/gpio/gpiochip512/device/of_node/phandle', P).
P = 7.
```

## Notes

- Sysfs export operations are asynchronous in the kernel. This pack includes retry-with-time-limit logic when waiting for exported paths.
- Default settings:
  - `sysfs_exported_time_limit = 1.0` seconds
  - `sysfs_exported_delay_time = 0.01` seconds
- You can override settings with SWI-Prolog `set_setting/2`.

## Tests and Examples

    - see `prolog/gpio_l298.plt`
    - see `prolog/pca9685_pcm.plt`

These include practical usage patterns for motor-control and PWM scenarios.

## License

MIT.
