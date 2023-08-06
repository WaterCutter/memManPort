/*
 * Auto_nuart_test.c
 *
 *  Created on: Jun 2, 2017
 *      Author: watercutter
 */



#define DARM_START_ADDR		(0x0006000000)
#define DARM_END_ADDR		(0x0007FFFFFF)

void main_app(){
	volatile unsigned int pa,pb,pc;
	heapInit();
	pa = pvPortMalloc(100);
	pb = pvPortMalloc(100);
	vPortFree(pb);
	pc = pvPortMalloc(100);
	while(1){
    	asm("nop");
    }
}

void irq_app(unsigned int intc_id){

}




