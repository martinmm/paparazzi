#ifndef CONFIG_NAZE32_H
#define CONFIG_NAZE32_H

#define BOARD_NAZE32

/* Naze32 has a 12MHz external clock and 72MHz internal */
#define EXT_CLK 12000000
#define AHB_CLK 72000000

/*
 * Onboard LEDs
 */


/* L0 red status led, on PB4 */
#ifndef USE_LED_1
#define USE_LED_1 1
#endif
#define LED_1_GPIO GPIOB
#define LED_1_GPIO_PIN GPIO4
#define LED_1_GPIO_ON gpio_clear
#define LED_1_GPIO_OFF gpio_set
#define LED_1_AFIO_REMAP {                            \
    rcc_periph_clock_enable(RCC_AFIO);                  \
    AFIO_MAPR |= AFIO_MAPR_SWJ_CFG_JTAG_OFF_SW_ON;  \
  }

/* L1 green status led, on PB3 */
#ifndef USE_LED_2
#define USE_LED_2 1
#endif
#define LED_2_GPIO GPIOB
#define LED_2_GPIO_PIN GPIO3
#define LED_2_GPIO_ON gpio_clear
#define LED_2_GPIO_OFF gpio_set
#define LED_2_AFIO_REMAP ((void)0)

/* 16Mbit flash on spi2 (Naze32 full) */
#define SPI_SELECT_SLAVE1_PORT GPIOB
#define SPI_SELECT_SLAVE1_PIN GPIO12

/*
 * UART pin configuration
 *
 * sets on which pins the UARTs are connected
 */
/* UART1 on main port */
#define UART1_GPIO_AF 0
#define UART1_GPIO_PORT_RX GPIO_BANK_USART1_RX
#define UART1_GPIO_RX GPIO_USART1_RX
#define UART1_GPIO_PORT_TX GPIO_BANK_USART1_TX
#define UART1_GPIO_TX GPIO_USART1_TX

/* UART2 on RC I/O, tx pin 5/id "3", rx pin 6/id "4") */
#define UART2_GPIO_AF 0
#define UART2_GPIO_PORT_RX GPIO_BANK_USART2_RX
#define UART2_GPIO_RX GPIO_USART2_RX
#define UART2_GPIO_PORT_TX GPIO_BANK_USART2_TX
#define UART2_GPIO_TX GPIO_USART2_TX

#if 0
/*
 * Spektrum
 */
/* The line that is pulled low at power up to initiate the bind process */
/* set to ppm/servo6 input pin on RC connector for now */
#define SPEKTRUM_BIND_PIN GPIO1
#define SPEKTRUM_BIND_PIN_PORT GPIOA

#define SPEKTRUM_UART1_RCC RCC_USART1
#define SPEKTRUM_UART1_BANK GPIO_BANK_USART1_RX
#define SPEKTRUM_UART1_PIN GPIO_USART1_RX
#define SPEKTRUM_UART1_AF 0
#define SPEKTRUM_UART1_IRQ NVIC_USART1_IRQ
#define SPEKTRUM_UART1_ISR usart1_isr
#define SPEKTRUM_UART1_DEV USART1
#endif

#if 0
#define SPEKTRUM_UART3_RCC RCC_USART3
#define SPEKTRUM_UART3_BANK GPIO_BANK_USART3_PR_RX
#define SPEKTRUM_UART3_PIN GPIO_USART3_PR_RX
#define SPEKTRUM_UART3_AF AFIO_MAPR_USART3_REMAP_PARTIAL_REMAP
#define SPEKTRUM_UART3_IRQ NVIC_USART3_IRQ
#define SPEKTRUM_UART3_ISR usart3_isr
#define SPEKTRUM_UART3_DEV USART3
#endif


/* PPM
 *
 * Default:  PPM config 1, input on PA0: RC I/O rx_ppm pin 3/id "1"
 * 6 servos: PPM config 2, input on PA7: RC I/O unused pin 8/id "6"
 */

#ifndef PPM_CONFIG
#define PPM_CONFIG 2
#else
#define PPM_CONFIG 1
#endif

#if PPM_CONFIG == 1
/* input on PA0 (ppm_in) */
#define USE_PPM_TIM2 1
#define PPM_CHANNEL         TIM_IC1
#define PPM_TIMER_INPUT     TIM_IC_IN_TI1
#define PPM_IRQ             NVIC_TIM2_IRQ
// Capture/Compare InteruptEnable and InterruptFlag
#define PPM_CC_IE           TIM_DIER_CC1IE
#define PPM_CC_IF           TIM_SR_CC1IF
#define PPM_GPIO_PORT       GPIOA
#define PPM_GPIO_PIN        GPIO0
#define PPM_GPIO_AF         0

// Move default ADC timer
#if USE_AD_TIM2
#undef USE_AD_TIM2
#endif
#define USE_AD_TIM1 1

#if USE_SERVOS_5AND6
#error PA0 does not work with 6 servos
#endif

#elif PPM_CONFIG == 2
/* input on PA7 (unused) */
#define USE_PPM_TIM3 1
#define PPM_CHANNEL         TIM_IC2
#define PPM_TIMER_INPUT     TIM_IC_IN_TI2
#define PPM_IRQ             NVIC_TIM3_IRQ
// Capture/Compare InteruptEnable and InterruptFlag
#define PPM_CC_IE           TIM_DIER_CC2IE
#define PPM_CC_IF           TIM_SR_CC2IF
#define PPM_GPIO_PORT       GPIOA
#define PPM_GPIO_PIN        GPIO7
#define PPM_GPIO_AF         0

// Move default ADC timer
#if USE_AD_TIM1
#undef USE_AD_TIM1
#endif
#define USE_AD_TIM2 1

#else
#error "Unknown PPM config"

#endif // PPM_CONFIG


/*
 * ADC
 */

/*
  ADC1 PB1/ADC9 (CURRENT)
  ADC2 PA4/ADC4 (VBAT)
  ADC3 PA1/ADC1 (RSSI)
  ADC4 PA5/ADC5 (EXT1)
*/

// Internal ADC for battery enabled by default
#ifndef USE_ADC_4
#define USE_ADC_4 1
#endif
#if USE_ADC_4
#define AD1_4_CHANNEL 4
#define ADC_4 AD1_4
#define ADC_4_GPIO_PORT GPIOA
#define ADC_4_GPIO_PIN GPIO4
#endif

/* allow to define ADC_CHANNEL_VSUPPLY in the airframe file*/
#ifndef ADC_CHANNEL_VSUPPLY
#define ADC_CHANNEL_VSUPPLY ADC_4
#endif

#if 0
/* current sensor (RC I/O pin 10, id "8") */
#if USE_ADC_1
#define AD1_1_CHANNEL 9
#define ADC_1 AD1_1
#define ADC_1_GPIO_PORT GPIOB
#define ADC_1_GPIO_PIN GPIO1
#endif

/* vbat */
#ifndef USE_ADC_2
#define USE_ADC_2 1
#endif
#if USE_ADC_2
#define AD1_2_CHANNEL 4
#define ADC_2 AD1_2
#define ADC_2_GPIO_PORT GPIOA
#define ADC_2_GPIO_PIN GPIO4
#endif


/* RSSI (RC I/O pin 4, id "2") */
#if USE_ADC_3
#define AD1_3_CHANNEL 1
#define ADC_3 AD1_3
#define ADC_3_GPIO_PORT GPIOA
#define ADC_3_GPIO_PIN GPIO1
#endif
#endif

#if 0
/* vbat */
#ifndef USE_ADC_4
#define USE_ADC_4 1
#endif
#if USE_ADC_4
#define AD1_4_CHANNEL 4
#define ADC_4 AD1_4
#define ADC_4_GPIO_PORT GPIOA
#define ADC_4_GPIO_PIN GPIO4
#endif
#endif

#if 0
#if USE_ADC_4
#define AD2_1_CHANNEL 5
#define ADC_4 AD2_1
#define ADC_4_GPIO_PORT GPIOA
#define ADC_4_GPIO_PIN GPIO5
#endif
#endif

#if 0
/* allow to define ADC_CHANNEL_VSUPPLY in the airframe file*/
#ifndef ADC_CHANNEL_VSUPPLY
#define ADC_CHANNEL_VSUPPLY ADC_4
#endif
#endif

/* 10k/1k resistor divider, 11 * 3.3V / 4096 */
#define DefaultVoltageOfAdc(adc) (0.008862*adc)


/* by default activate onboard baro */
#ifndef USE_BARO_BOARD
#define USE_BARO_BOARD 1
#endif

/*
 * I2C
 */
/* RC port */
#define I2C2_GPIO_PORT GPIOB
#define I2C2_GPIO_SCL GPIO10
#define I2C2_GPIO_SDA GPIO11


/*
 * PWM
 *
 * Servo output numbering on silkscreen starts with '1'
 *
 * silk       standard  USE_SERVOS_5AND6
 *
 * '1'  PA8             servo1
 * '2'  PA11            servo2
 * '3'  PB6   servo1    servo3
 * '4'  PB7   servo2    servo4
 * '5'  PB8   servo3    servo5
 * '6'  PB9   servo4    servo6
 *
 * PPM_in:    PA0       PA7
 *
 */

#if USE_SERVOS_5AND6

#define ACTUATORS_PWM_NB 6

/* servos 1-2 */
#define PWM_USE_TIM1 1
#define USE_PWM1 1
#define USE_PWM2 1

/* servos 3-6 */
#define PWM_USE_TIM4 1
#define USE_PWM3 1
#define USE_PWM4 1
#define USE_PWM5 1
#define USE_PWM6 1

#if USE_PWM1
#define PWM_SERVO_1 0
#define PWM_SERVO_1_TIMER TIM1
#define PWM_SERVO_1_GPIO GPIOA
#define PWM_SERVO_1_PIN GPIO8
#define PWM_SERVO_1_AF 0
#define PWM_SERVO_1_OC TIM_OC1
#define PWM_SERVO_1_OC_BIT (1<<0)
#else
#define PWM_SERVO_1_OC_BIT 0
#endif

#if USE_PWM2
#define PWM_SERVO_2 1
#define PWM_SERVO_2_TIMER TIM1
#define PWM_SERVO_2_GPIO GPIOA
#define PWM_SERVO_2_PIN GPIO11
#define PWM_SERVO_2_AF 0
#define PWM_SERVO_2_OC TIM_OC4
#define PWM_SERVO_2_OC_BIT (1<<3)
#else
#define PWM_SERVO_2_OC_BIT 0
#endif

#if USE_PWM3
#define PWM_SERVO_3 2
#define PWM_SERVO_3_TIMER TIM4
#define PWM_SERVO_3_GPIO GPIOB
#define PWM_SERVO_3_PIN GPIO6
#define PWM_SERVO_3_AF 0
#define PWM_SERVO_3_OC TIM_OC1
#define PWM_SERVO_3_OC_BIT (1<<0)
#else
#define PWM_SERVO_3_OC_BIT 0
#endif

#if USE_PWM4
#define PWM_SERVO_4 3
#define PWM_SERVO_4_TIMER TIM4
#define PWM_SERVO_4_GPIO GPIOB
#define PWM_SERVO_4_PIN GPIO7
#define PWM_SERVO_4_AF 0
#define PWM_SERVO_4_OC TIM_OC2
#define PWM_SERVO_4_OC_BIT (1<<1)
#else
#define PWM_SERVO_4_OC_BIT 0
#endif

#if USE_PWM5
#define PWM_SERVO_5 4
#define PWM_SERVO_5_TIMER TIM4
#define PWM_SERVO_5_GPIO GPIOB
#define PWM_SERVO_5_PIN GPIO8
#define PWM_SERVO_5_AF 0
#define PWM_SERVO_5_OC TIM_OC3
#define PWM_SERVO_5_OC_BIT (1<<2)
#else
#define PWM_SERVO_5_OC_BIT 0
#endif

#if USE_PWM6
#define PWM_SERVO_6 5
#define PWM_SERVO_6_TIMER TIM4
#define PWM_SERVO_6_GPIO GPIOB
#define PWM_SERVO_6_PIN GPIO9
#define PWM_SERVO_6_AF 0
#define PWM_SERVO_6_OC TIM_OC4
#define PWM_SERVO_6_OC_BIT (1<<3)
#else
#define PWM_SERVO_6_OC_BIT 0
#endif

/* servos 1-2 on TIM1 */
#define PWM_TIM1_CHAN_MASK (PWM_SERVO_1_OC_BIT|PWM_SERVO_2_OC_BIT)
/* servos 3-6 on TIM4 */
#define PWM_TIM4_CHAN_MASK (PWM_SERVO_3_OC_BIT|PWM_SERVO_4_OC_BIT|PWM_SERVO_5_OC_BIT|PWM_SERVO_6_OC_BIT)

#else //USE_SERVOS_5AND6

#define ACTUATORS_PWM_NB 4

/* servos 1-4 */
#define PWM_USE_TIM4 1
#define USE_PWM1 1
#define USE_PWM2 1
#define USE_PWM3 1
#define USE_PWM4 1

#if USE_PWM1
#define PWM_SERVO_1 0
#define PWM_SERVO_1_TIMER TIM4
#define PWM_SERVO_1_GPIO GPIOB
#define PWM_SERVO_1_PIN GPIO6
#define PWM_SERVO_1_AF 0
#define PWM_SERVO_1_OC TIM_OC1
#define PWM_SERVO_1_OC_BIT (1<<0)
#else
#define PWM_SERVO_1_OC_BIT 0
#endif

#if USE_PWM2
#define PWM_SERVO_2 1
#define PWM_SERVO_2_TIMER TIM4
#define PWM_SERVO_2_GPIO GPIOB
#define PWM_SERVO_2_PIN GPIO7
#define PWM_SERVO_2_AF 0
#define PWM_SERVO_2_OC TIM_OC2
#define PWM_SERVO_2_OC_BIT (1<<1)
#else
#define PWM_SERVO_2_OC_BIT 0
#endif

#if USE_PWM3
#define PWM_SERVO_3 2
#define PWM_SERVO_3_TIMER TIM4
#define PWM_SERVO_3_GPIO GPIOB
#define PWM_SERVO_3_PIN GPIO8
#define PWM_SERVO_3_AF 0
#define PWM_SERVO_3_OC TIM_OC3
#define PWM_SERVO_3_OC_BIT (1<<2)
#else
#define PWM_SERVO_3_OC_BIT 0
#endif

#if USE_PWM4
#define PWM_SERVO_4 3
#define PWM_SERVO_4_TIMER TIM4
#define PWM_SERVO_4_GPIO GPIOB
#define PWM_SERVO_4_PIN GPIO9
#define PWM_SERVO_4_AF 0
#define PWM_SERVO_4_OC TIM_OC4
#define PWM_SERVO_4_OC_BIT (1<<3)
#else
#define PWM_SERVO_4_OC_BIT 0
#endif

/* servos 1-4 on TIM4 */
#define PWM_TIM4_CHAN_MASK (PWM_SERVO_1_OC_BIT|PWM_SERVO_2_OC_BIT|PWM_SERVO_3_OC_BIT|PWM_SERVO_4_OC_BIT)

#endif //USE_SERVOS_5AND6

/* Default actuators driver */
#define DEFAULT_ACTUATORS "subsystems/actuators/actuators_pwm.h"
#define ActuatorDefaultSet(_x,_y) ActuatorPwmSet(_x,_y)
#define ActuatorsDefaultInit() ActuatorsPwmInit()
#define ActuatorsDefaultCommit() ActuatorsPwmCommit()


#endif /* CONFIG_NAZE32_H */

