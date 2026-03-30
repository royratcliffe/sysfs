:- begin_tests(pca9685_pcm).
:- use_module(pwm).
:- use_module(io).

pwmchip(PWMChip) :- sysfs_pwmchip_read(device/name, PWMChip, 'pca9685-pwm').

pwm(PWM) :- pwmchip(PWMChip), sysfs_pwm(PWMChip, _, PWM).

enable(PWM, Enable), var(Enable) =>
    pwm(PWM), sysfs_read(PWM, enable(Enable)).

ensure_export(PWM) :-
    pwmchip(Chip),
    between(11, 15, Export),
    sysfs_pwm_ensure_exported(Chip, Export, PWM).

read_pwm(PWM, Term) :- pwm(PWM), sysfs_pwm_read(PWM, Term).

write_pwm(PWM, Term), var(PWM) => pwm(PWM), sysfs_pwm_write(PWM, Term).
write_pwm(PWM, Term) => sysfs_pwm_write(PWM, Term).

percent(Percent) :-
    forall(ensure_export(PWM),
           (   write_pwm(PWM, duty_cycle(Percent, percent)),
               sleep(0.5)
           )).

test(period, NS == 5079040) :-
    pwmchip(Chip),
    sysfs_pwm_ensure_exported(Chip, 11, PWM11),
    sysfs_pwm_read(PWM11, period(NS, ns)).

duty_cycle :-
    pwmchip(Chip),
    between(11, 15, Chan), sysfs_pwm_ensure_exported(Chip, Chan, PWM),
    sysfs_pwm_write(PWM, enable(0)).

dance :-
    forall(between(-5, 5, Percent), (percent(20 + Percent), sleep(0.5))),
    forall(between(-5, 5, Percent), (percent(20 - Percent), sleep(0.5))).

:- end_tests(pca9685_pcm).
