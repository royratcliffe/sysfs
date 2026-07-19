:- begin_tests(pca9685_pcm).
:- use_module(library(sysfs/pwmchip)).
:- use_module(library(sysfs/pwm)).

pwmchip(PWMChip) :- once(sysfs_pwmchip_read(device/name, PWMChip, 'pca9685-pwm')).

pwm(PWM) :- pwmchip(PWMChip), sysfs_pwm(PWMChip, _, PWM).

enable(PWM, Enable), var(Enable) =>
    pwm(PWM), sysfs_pwm_read(PWM, enable(Enable)).
enable(PWM, Enable) =>
    pwm(PWM), sysfs_pwm_write(PWM, enable(Enable)).

ensure_export(Export, PWM) :-
    pwmchip(PWMChip),
    sysfs_pwm(PWMChip, Export, PWM),
    sysfs_pwm_ensure_exported(PWM).

ensure_export(PWM) :-
    between(11, 15, Export),
    ensure_export(Export, PWM).

read_pwm(PWM, Term) :- pwm(PWM), sysfs_pwm_read(PWM, Term).

write_pwm(PWM, Term), var(PWM) => pwm(PWM), sysfs_pwm_write(PWM, Term).
write_pwm(PWM, Term) => sysfs_pwm_write(PWM, Term).

percent(Percent) :-
    forall(ensure_export(PWM),
           (   write_pwm(PWM, duty_cycle(Percent, percent)),
               sleep(0.5)
           )).

test(period, NS == 5079040) :-
    ensure_export(11, PWM11),
    sysfs_pwm_read(PWM11, period(NS, ns)).

duty_cycle :-
    between(11, 15, Export),
    ensure_export(Export, PWM),
    sysfs_pwm_write(PWM, enable(0)).

dance :-
    forall(between(-5, 5, Percent), (percent(20 + Percent), sleep(0.5))),
    forall(between(-5, 5, Percent), (percent(20 - Percent), sleep(0.5))).

:- end_tests(pca9685_pcm).
