################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
S_SRCS += \
../asm/a53_aarch64_driver.s \
../asm/start_up.s 

OBJS += \
./asm/a53_aarch64_driver.o \
./asm/start_up.o 


# Each subdirectory must supply rules for building sources it contributes
asm/%.o: ../asm/%.s
	@echo 'Building file: $<'
	@echo 'Invoking: Arm Assembler 6'
	armclang.exe --target=aarch64-arm-none-eabi -mcpu=cortex-a53+nocrypto -g -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


