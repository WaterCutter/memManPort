################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/a53_aarch64_driver.c \
../src/heap_man.c \
../src/main.c 

OBJS += \
./src/a53_aarch64_driver.o \
./src/heap_man.o \
./src/main.o 

C_DEPS += \
./src/a53_aarch64_driver.d \
./src/heap_man.d \
./src/main.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: Arm C Compiler 6'
	armclang.exe --target=aarch64-arm-none-eabi -mcpu=cortex-a53+nocrypto -DUSE_SERIAL_PORT -DSTANDALONE -xc -std=gnu11 -fno-lto -O0 -g -MD -MP -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


