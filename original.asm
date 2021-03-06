#make_bin#

#LOAD_SEGMENT=FFFFh#
#LOAD_OFFSET=0000h#

#CS=0000h#
#IP=0000h#

#DS=0000h#
#ES=0000h#

#SS=0000h#
#SP=FFFEh#

#AX=0000h#
#BX=0000h#
#CX=0000h#
#DX=0000h#
#SI=0000h#
#DI=0000h#
#BP=0000h#

; add your code here
         jmp     st1 
         db     509 dup(0)

;IVT entry for 80H
         
         dw     t_isr
         dw     0000
         db     508 dup(0)
;IVT entry for ///81H
         
         dw     t_isr2
         dw     0000
         db     508 dup(0)

         nop
         dw      0000
         dw      0000
         dw      ad_isr
         dw      0000
		 
		 db     1012 dup(0)
;main program

;--------------- Start Inits-------------------------;
st1:      cli 
; intialize ds, es,ss to start of RAM
          mov       ax,0200h
          mov       ds,ax
          mov       es,ax
          mov       ss,ax
          mov       sp,0FFFEH

;1st timer - 0.1 second - 8253 clock is 10 KHz-divide by 10,00d
;Mode 3 : We give 0.1 seconds to read and 0.1 seconds for a time delay in between next read and current read
		  mov       al,00110110b
		  out       0Eh,al
		  mov       al,0e8h
		  out       08h,al
		  mov       al,03h
		  out       08h,al

;2nd timer - 8*3600 second - 8253 clock is 1 Hz-divide by 28800d
;Mode 0 : Divide the day into three 8 hour partitions. (1am to 9am) to (9am to 5pm) to (5pm to 1am)
;The counter should send an interrupt once at 9am and second at 5pm so connect a NOT gate to the output of this counter and give it as input to 8259
	
		  mov       al,01110110b
		  out       0Eh,al
		  mov       al,80h
		  out       08h,al
		  mov       al,70h
		  out       08h,al


;8259 intialize - vector no. ///80h, edge triggered
;8259 -	enable IRO alone use AEOI	  
		  mov       al,00010011b ;edge triggered
		  out       10h,al
		  mov       al,80h ;starting vector number is 80h
		  out       12h,al
		  mov       al,03h ;automatic end of interrupt 
		  out       12h,al
		  mov       al,0FDh
		  out       12h,al
		  
;start
  
;for required value of moisture content(assumed voltage :2.5v of 3v:digital 8-bit eqv->213 of 256)
  mov [00fdh],213 
 
 ;for flag of one routine
  mov [00fbh],0

;The number of maximum interrupts in one day is 2
  mov [00feh],2


;intialise port b  as input & a & c as output
          mov       al,10000010b
		  out 		06h,al 
  sti

;loop till isr
x2:       jmp       x2  

;-------------------------- Interrupt Service Routine -----------------------------------------------;

;INTERRUPT Service Routine: Checks at 9am and 5pm
t_isr2:
          mov al,0
          cmp [00feh],0
          jnz x1 
	
	  ;if two interrupts at 9am and 5pm are already called then skip the 1 am one
          mov [00feh],2        
          iret
	
	x1:
		;select ch0 
		mov	al,00
		out	00h,al  
		
		;give ale  
		mov	al,00100000b
		out	00h,al 
		 
		;give soc  
		mov	al,00110000b
		out	00h,al
		nop
		nop
		nop
		nop

		;make soc 0 
		mov       al,00010000b
		out       00h,al  

		;make ale 0 
		mov       al,00000000b
		out       00h,al


		;decrement value at 00feh
          	mov al,1
          	sub [00feh],al
       
         	;enable for t_isr
        	mov [00fch],1

	x5:     cmp     [00fbh],1
         	jnz     x5

         	;disable the enable for t_isr
         	mov [00fch],0
iret 
		  

                 
;INTERRUPT Service Routine: for 0.1 sec feedback system during sprinkler activation
t_isr:

	;check for enable
	cmp  [00fch],1 ;Flag if it is 9am or 5 pm
	jz   x7
	iret             


	x7:     mov al,1
                mov [00ffh],al
                nop ; Give slight Delay
		nop
		nop
		nop
	
		;make soc 0 
		mov       al,00010000b
		out       00h,al
  
		;make ale 0  
		mov       al,00000000b
		out       00h,al
     
          
	x4:     mov al,1 
        	cmp [00ffh],al 
        	jz x4 

iret

;NMI of EOC
ad_isr:           
	mov       al,00001000b   ;oe enable
	out	  00h,al
	in        al,02h
        cmp       al,[0ffdh]
        jge       x3                 
	mov       al,0ffh
	out       06h,al

        ;setting flag to be 1 to show that routine is over                       
	x3:       mov	[00fbh],1 
	
	; for single execution of nmi in 0.1 s interrupt
	x6:       mov	[00ffh],0 
iret
          
          
