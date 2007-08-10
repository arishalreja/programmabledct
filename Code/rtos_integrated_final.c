/*******************************************************************************
********************************************************************************
**                                                                            **
**                     TASK SWITCHING                                         **
**                                                                            **
********************************************************************************
*******************************************************************************/

enum
{
   TASK_RUNNING   = 0x00,
   TASK_BLOCKED   = 0x01,
   TASK_SLEEPING  = 0x02,
   TASK_SUSPENDED = 0x04
};

typedef struct _task Task;
typedef struct _semaphore Semaphore;
struct _task
{
   // members required at initialization...
   // 
   Task        * next_task;
   int         * stack_pointer;
   char          status;
   unsigned char priority;
   const char *  name;
   char *        stack_bottom;
   char *        stack_top;

   // members used later on
   //
   char          sema_ret;
   unsigned char saved_priority;
   Semaphore  *  waiting_for;
   Task *        next_waiting_task;
   int           sleep_count;
};

extern Task * current_task;
extern Task task_idle;
//cclin

int flag=0;
int flag2=0;

char	*adr_ex_mem;
char	*adr_dct;
int     *adr_ex_dct;
char    *fix_int;
int 	*base_adr;

struct _semaphore
{
   int          counter;
   Task *       next_waiting;
   Task *       last_waiting;
   const char * name;
};
Semaphore rx_sema =    { 0, 0, 0, "rx_semaphore"   };
Semaphore t2_control = { 0, 0, 0, "task 2 control" };
Semaphore t3_control = { 0, 0, 0, "task 3 control" };
Semaphore serial_out = { 1, 0, 0, "serial out"     };
Semaphore tx_sema =    { 16, 0, 0, "tx_semaphore"  };

void switch_tasks()   // interrupts disabled !
{
Task * next = 0;
Task * t = current_task;

   /* for performance reasons, we hand-code the following:
 
   do { if (  !(t = t->next_task)->status       // t is running and
           && (!next                            // no next found so far,
              || t->priority > next->priority   // or t has higher priority
              )
           )  next = t;
      } while (t != current_task);
   */

   ASM("
st_loop:
	MOVE	0(SP), RR		; RR = t
	MOVE	(RR), RR		; RR = t->next_task
	MOVE	RR, 0(SP)		; t  = t->next_task
	ADD	RR, #4			; RR = & t->status
	MOVE	(RR), RS		; RR = t->status
	JMP	RRNZ, st_next_task	; jump if (status != 0)
					;
	MOVE	2(SP), RR		; RR = next
	JMP	RRZ, st_accept		; jump if (next == 0)
					;
	ADD	RR, #5			; RR = & next->priority
	MOVE	(RR), RS		; RR = next->priority
	MOVE	RR, LL			; LL = next->priority
	MOVE	0(SP), RR		; RR = t
	ADD	RR, #5			; RR = & t->priority
	MOVE	(RR), RS		; RR = t->priority
	SGE	LL, RR			; RR = (next->priority >= t->priority)
	JMP	RRNZ, st_next_task	; jump if (next->priority > t->priority)
st_accept:				;
	MOVE	0(SP), RR		; RR = t
	MOVE	RR, 2(SP)		; next = t
st_next_task:				;
	MOVE	0(SP), RR		; RR = t
	MOVE	(Ccurrent_task), LL	; LL = current_task
	SNE	LL, RR			; RR = (t != current_task)
	JMP	RRNZ, st_loop		;
	");

   if (current_task != next)
      {
        current_task->stack_pointer = (int *)ASM(" LEA  0(SP), RR");
        current_task = next;
        current_task->stack_pointer;  ASM(" MOVE RR, SP");
      }
}
//-----------------------------------------------------------------------------
void P(Semaphore * sema)
{
   ASM(" DI");

   if (--sema->counter < 0)
      {
        // this task blocks
        //
        current_task->waiting_for = sema;
        current_task->next_waiting_task = 0;
        current_task->status |= TASK_BLOCKED;

        if (sema->next_waiting)   // some tasks blocked already on sema
           sema->last_waiting->next_waiting_task = current_task;
        else                      // first task blocked on sema
           sema->next_waiting = current_task;

        sema->last_waiting = current_task;
        switch_tasks();
      }

   ASM(" RETI");
}
//-----------------------------------------------------------------------------
//
// return non-zero if timeout occured
//
char P_timed(Semaphore * sema, unsigned int ticks)
{
char ret = 0;

   ASM(" DI");

   if (--sema->counter < 0)
      {
        // this task blocks
        //
        current_task->waiting_for = sema;
        current_task->sleep_count = ticks;
        current_task->next_waiting_task = 0;
        current_task->status |= TASK_BLOCKED | TASK_SLEEPING;
        current_task->sema_ret = 0;

        if (sema->next_waiting)   // some tasks blocked already on sema
           sema->last_waiting->next_waiting_task = current_task;
        else                      // first task blocked on sema
           sema->next_waiting = current_task;


        switch_tasks();
        ret = current_task->sema_ret;
      }

   ASM(" EI");
   return ret;
}
//-----------------------------------------------------------------------------
//
// return non-zero if task switch required
//
char Vint(Semaphore * sema)   // interrupts disabled !
{
Task * next = sema->next_waiting;

   ++sema->counter;

   if (next)   // waiting queue not empty: remove first waiting
      {
        next->status &= ~(TASK_BLOCKED | TASK_SLEEPING);

        sema->next_waiting = next->next_waiting_task;
        if (!sema->next_waiting)   sema->last_waiting = 0;

        return next->priority > current_task->priority;
      }

   return 0;
}
//-----------------------------------------------------------------------------
void V(Semaphore * sema)
{
   ASM(" DI");
   if (Vint(sema))   switch_tasks();
   ASM(" RETI");
}
/*******************************************************************************
********************************************************************************
**                                                                            **
**                     INTERRUPT HANDLERS                                     **
**                                                                            **
********************************************************************************
*******************************************************************************/

unsigned char serial_in_buffer[16];
unsigned char serial_in_get       = 0;
unsigned char serial_in_put       = 0;
unsigned int  serial_in_overflows = 0;

char rx_interrupt()
{
char c = ASM(" IN   (IN_RX_DATA), RU");

   if (rx_sema.counter < sizeof(serial_in_buffer))
      {
        serial_in_buffer[serial_in_put] = c;
        if (++serial_in_put >= sizeof(serial_in_buffer))   serial_in_put = 0;
        return Vint(&rx_sema);
      }
   else
      {
        ++serial_in_overflows;
        return 0;
      }
}
//-----------------------------------------------------------------------------

unsigned char serial_out_buffer[16];
unsigned char serial_out_get = 0;
unsigned char serial_out_put = 0;

char tx_interrupt()
{
   if (tx_sema.counter < sizeof(serial_out_buffer))
      {
        serial_out_buffer[serial_out_get];
        ASM(" OUT  R, (OUT_TX_DATA)");
        if (++serial_out_get >= sizeof(serial_out_buffer))   serial_out_get = 0;
        return Vint(&tx_sema);
      }
   else
      {
        ASM(" MOVE #0x05, RR");            // RxInt and TimerInt
        ASM(" OUT  R, (OUT_INT_MASK)");
        return 0;
      }
}
//-----------------------------------------------------------------------------

unsigned int  milliseconds    = 0;
unsigned int  seconds_low     = 0;
unsigned int  seconds_mid     = 0;
unsigned int  seconds_high    = 0;
unsigned char seconds_changed = 0;

void timer_interrupt()
{
Task * t = current_task;
Semaphore * s;
Task * ts;

   ASM(" OUT  R, (OUT_RESET_TIMER)");
   if (++milliseconds == 10)
      {
         milliseconds = 0;
         seconds_changed = 0xFF;
         if (++seconds_low == 0)
            {
              if (++seconds_mid == 0)   ++seconds_high;
            }
      }

   do {
        if (!--(t->sleep_count) && (t->status & TASK_SLEEPING))
           {
             t->status &= ~TASK_SLEEPING;
             if (t->status & TASK_BLOCKED)   // timed P
                {
                  t->status &= ~TASK_BLOCKED;
                  t->sema_ret = -1;
                  s = t->waiting_for;
                  ++s->counter;
                  ts = s->next_waiting;
                  if (t == ts)                    // t is first waiting
                     {
                       if (t == s->last_waiting)
                          { // t is also last (thus, the only) waiting
                            s->next_waiting = 0;
                            s->last_waiting = 0;
                          }
                       else
                          { // t is first of several waiting (thus, not last)
                            s->next_waiting = t->next_waiting_task;
                          }
                     }
                  else                            // t is subsequent waiting
                     {
                       while (t != ts->next_waiting_task)
                             ts = ts->next_waiting_task;
                       ts->next_waiting_task = t->next_waiting_task;
                       if (t == s->last_waiting)   // t is last waiting
                          s->last_waiting = ts;    // now ts is last waiting
                     }
                }
           }
      } while (current_task != (t = t->next_task));
}
//-----------------------------------------------------------------------------
void interrupt()
{
char ts_1 = 0;
char ts_2 = 0;

   ASM(" MOVE RR, -(SP)");
   ASM(" MOVE LL, RR");
   ASM(" MOVE RR, -(SP)");

   if (ASM(" IN   (IN_STATUS), RU") & 0x10)   ts_1  = rx_interrupt();
   if (ASM(" IN   (IN_STATUS), RU") & 0x20)   ts_2  = tx_interrupt();
   if (ASM(" IN   (IN_STATUS), RU") & 0x40)
      { timer_interrupt();   ts_1 = -1; 
   	//cclin 0417
   	current_task->status = TASK_SLEEPING;
   	current_task->sleep_count = 2;
      }

   if (ts_1 | ts_2)   switch_tasks();

   ASM(" MOVE (SP)+, RR");
   ASM(" MOVE RR, LL");
   ASM(" MOVE (SP)+, RR");
   ASM(" ADD  SP, #2");
   ASM(" RETI");
}
//-----------------------------------------------------------------------------
void sleep(int millisecs)
{
   ASM(" DI");
   current_task->sleep_count = millisecs;
   current_task->status      = TASK_SLEEPING;
   switch_tasks();
   ASM(" RETI");
}
//-----------------------------------------------------------------------------
void deschedule()
{
   ASM(" DI");
   switch_tasks();
   ASM(" RETI");
}
/*******************************************************************************
********************************************************************************
**                                                                            **
**                     UTILITY FUNCTIONS                                      **
**                                                                            **
********************************************************************************
*******************************************************************************/

int strlen(const char * buffer)
{
const char * from = buffer;

    while (*buffer)   buffer++;

   return buffer - from;
}
/*******************************************************************************
********************************************************************************
**                                                                            **
**                     SERIAL OUTPUT                                          **
**                                                                            **
********************************************************************************
*******************************************************************************/

int putchr(char c)
{
   P(&tx_sema);   // get free position

   serial_out_buffer[serial_out_put] = c;
   if (++serial_out_put >= sizeof(serial_out_buffer))   serial_out_put = 0;
   ASM(" MOVE #0x07, RR");            // RxInt and TxInt and TimerInt
   ASM(" OUT  R, (OUT_INT_MASK)");
   1;
}
//-----------------------------------------------------------------------------
void print_n(char c, int count)
{
    for (; count > 0; --count)   putchr(c);
}
//-----------------------------------------------------------------------------
void print_string(const char * buffer)
{
    while (*buffer)   putchr(*buffer++);
}
//-----------------------------------------------------------------------------
void print_hex(char * dest, unsigned int value, const char * hex)
{
   if (value >= 0x1000)   *dest++ = hex[(value >> 12) & 0x0F];
   if (value >=  0x100)   *dest++ = hex[(value >>  8) & 0x0F];
   if (value >=   0x10)   *dest++ = hex[(value >>  4) & 0x0F];
   *dest++ = hex[value  & 0x0F];
   *dest = 0;
}
//-----------------------------------------------------------------------------
void print_unsigned(char * dest, unsigned int value)
{
   if (value >= 10000)    *dest++ = '0' + (value / 10000);
   if (value >=  1000)    *dest++ = '0' + (value /  1000) % 10;
   if (value >=   100)    *dest++ = '0' + (value /   100) % 10;
   if (value >=    10)    *dest++ = '0' + (value /    10) % 10;
   *dest++ = '0' + value % 10;
   *dest = 0;
}
//-----------------------------------------------------------------------------
int print_item(const char * buffer, char flags, char sign, char pad,
               const char * alt, int field_w, int min_w, char min_p)
{
   // [fill] [sign] [alt] [pad] [buffer] [fill]
   //        ----------- len ----------- 
int filllen = 0;
int signlen = 0;
int altlen  = 0;
int padlen  = 0;
int buflen  = strlen(buffer);
int len;
int i;

   if (min_w > buflen)          padlen = min_w - buflen;
   if (sign)                    signlen = 1;
   if (alt && (flags & 0x01))   altlen = strlen(alt);

   len = signlen + altlen + padlen + buflen;

   if (0x02 & ~flags)   print_n(pad, field_w - len);   // right align

   if (sign)   putchr(sign);
   if (alt)
      {
        if (flags & 0x01)   print_string(alt);
      }

   for (i = 0; i < padlen; i++)   putchr(min_p);
   print_string(buffer);

   if (0x02 & flags)   print_n(pad, field_w - len);   // left align

   return len;
}
//-----------------------------------------------------------------------------
void wishbone()
{
	int a;
	int b;
	int c;
	ASM("
;
; Wishbone Block Write Subroutine, for 64 , 1 byte (8 bit) values
;
; Arish Alreja, Georgia Tech
; Ramanathan Palaniappan, Georgia Tech
;
; $(Date) : 03/21/2007
;
;
;      MOVE    #0x0005,RR  ; Base address for DCT Data
;      MOVE    RR,SP
;      MOVE    #0xFFC0,RR  ; Initialize RR with -64
;Loop: 
;      MOVE    (SP)+, LL
;      MOVE    LL, (RR)
;      ADD     RR,#0x0001  ;      
;      JMP     RRNZ,Loop   ; If yes, then 64 data have been transferred

      MOVE    #0x0005,RR  ; Base address for DCT Data
      MOVE    RR,2(SP)
      MOVE    #0xFF00,RR  ; Initialize RR with -64
      MOVE    RR,LL
      MOVE    RR,1(SP)
      MOVE    #64,RR  
      MOVE    RR,0(SP)
Loop: 
      MOVE    2(SP), RR
      MOVE    (RR), RR
      MOVE    RR, (LL)

      MOVE    2(SP), RR
      ADD     RR,#0x0001
      MOVE    RR,2(SP)
      
      MOVE    LL, RR
      ADD     RR,#0x0001
      MOVE    RR, LL

      MOVE    0(SP),RR
      SUB     RR,#1
      MOVE    RR,0(SP)
      
      JMP     RRNZ,Loop   ; If yes, then 64 data have been transferred
      ;RETI
      ;RETI
	    ");
//   ASM(" MOVE RR, -(SP)");
//   ASM(" MOVE LL, RR");
//   ASM(" MOVE RR, -(SP)");
//   ASM(" MOVE (SP)+, RR");
//   ASM(" MOVE RR, LL");
//   ASM(" MOVE (SP)+, RR");
}
int test1(int tmp)
{
	tmp = tmp +1;
	return tmp;
}
int test2(int tmp)
{
	tmp = tmp -1;
	return tmp;
}
int test(const char * format, ...)
{
const char **  args = 1 + &format;
int            len = 0;
char           c;
char           flags;
char           sign;
char           pad;
const char *   alt;
int            field_w;
int            min_w;
unsigned int * which_w;
char           buffer[12];
int		tmp;

	tmp=0;
   while (c = *format++)
       {
         if (c != '%')   { len +=putchr(c);   continue; }
	tmp++;
         flags   = 0;
         sign    = 0;
         pad     = ' ';
         field_w = 0;
         min_w   = 0;
         which_w = &field_w;
         for (;;)
             {
             }
       }
   return len;
}
//-----------------------------------------------------------------------------
int printf(const char * format, ...)
{
const char **  args = 1 + &format;
int            len = 0;
char           c;
char           flags;
char           sign;
char           pad;
const char *   alt;
int            field_w;
int            min_w;
unsigned int * which_w;
char           buffer[12];

   while (c = *format++)
       {
         if (c != '%')   { len +=putchr(c);   continue; }

         flags   = 0;
         sign    = 0;
         pad     = ' ';
         field_w = 0;
         min_w   = 0;
         which_w = &field_w;
         for (;;)
             {
               switch(c = *format++)
                  {
                    case 'X': print_hex(buffer, (unsigned int)*args++,
					"0123456789ABCDEF");
                              len += print_item(buffer, flags, sign, pad,
                                                "0X", field_w, min_w, '0');
                              break;

                    case 'd': if (((int)*args) < 0)
                                 {
                                   sign = '-';
                                   *args = (char *)(- ((int)*args));
                                 }
                              print_unsigned(buffer, ((int)*args++));
                              len += print_item(buffer, flags, sign, pad,
                                                "", field_w, min_w, '0');
                              break;

                    case 's': len += print_item(*args++, flags & 0x02, 0, ' ',
                                                "", field_w, min_w, ' ');
                              break;

                    case 'u': print_unsigned(buffer, (unsigned int)*args++);
                              len += print_item(buffer, flags, sign, pad,
                                                "", field_w, min_w, '0');
                              break;

                    case 'x': print_hex(buffer, (unsigned int)*args++,
					"0123456789abcdef");
                              len += print_item(buffer, flags, sign, pad,
                                                "0x", field_w, min_w, '0');
                              break;

                    case 'c': len += putchr((int)*args++);    break;

                    case '#': flags |= 0x01;                  continue;
                    case '-': flags |= 0x02;                  continue;
                    case ' ': if (!sign)  sign = ' ';         continue;
                    case '+': sign = '+';                     continue;
                    case '.': which_w = &min_w;               continue;

                    case '0': if (*which_w)   *which_w *= 10;
                              else            pad = '0';
                              continue;

                    case '1': *which_w = 10 * *which_w + 1;   continue;
                    case '2': *which_w = 10 * *which_w + 2;   continue;
                    case '3': *which_w = 10 * *which_w + 3;   continue;
                    case '4': *which_w = 10 * *which_w + 4;   continue;
                    case '5': *which_w = 10 * *which_w + 5;   continue;
                    case '6': *which_w = 10 * *which_w + 6;   continue;
                    case '7': *which_w = 10 * *which_w + 7;   continue;
                    case '8': *which_w = 10 * *which_w + 8;   continue;
                    case '9': *which_w = 10 * *which_w + 9;   continue;
                    case '*': *which_w = (int)*args++;        continue;

                    case 0:   format--;   // premature end of format
                              break;

                    default:  len += putchr(c);
                              break;
                  }
                break;
             }
       }
   return len;
}
/*******************************************************************************
********************************************************************************
**                                                                            **
**                     SERIAL INPUT                                           **
**                                                                            **
********************************************************************************
*******************************************************************************/

int getchr()
{
char c;

   P(&rx_sema);

   c = serial_in_buffer[serial_in_get];
   if (++serial_in_get >= sizeof(serial_in_buffer))   serial_in_get = 0;
   return c;
}
//-----------------------------------------------------------------------------
int getchr_timed(unsigned int ticks)
{
char c;

   c = P_timed(&rx_sema, ticks);
   if (c)   return -1;   // if rx_sema timed out

   c = serial_in_buffer[serial_in_get];
   if (++serial_in_get >= sizeof(serial_in_buffer))   serial_in_get = 0;
   return c;
}
//-----------------------------------------------------------------------------
char peekchr()
{
char ret;

   P(&rx_sema);
   ret = serial_in_buffer[serial_in_get];
   V(&rx_sema);

   return ret;
}
//-----------------------------------------------------------------------------
char getnibble(char echo)
{
char c  = peekchr();
int ret = -1;

   if      ((c >= '0') && (c <= '9'))   ret = c - '0';
   else if ((c >= 'A') && (c <= 'F'))   ret = c - 0x37;
   else if ((c >= 'a') && (c <= 'f'))   ret = c - 0x57;

   if (ret != -1)   // valid hex char
      {
        getchr();
        if (echo)   putchr(c);
      }
   return ret;
}
//-----------------------------------------------------------------------------
int gethex(char echo)
{
int  ret = 0;
char c;

   while ((c = getnibble(echo)) != -1)   ret = (ret << 4) | c;
   return ret;
}
/*******************************************************************************
********************************************************************************
**                                                                            **
**                     main and its helpers                                   **
**                                                                            **
********************************************************************************
*******************************************************************************/

//-----------------------------------------------------------------------------
void init_stack()
{
char * bottom = current_task->stack_bottom;

   while (bottom < (char *)ASM(" LEA 0(SP), RR"))   *bottom++ = 'S';
}
//-----------------------------------------------------------------------------

extern char * end_text;

void init_unused()   // must ONLY be called by idle task
{
char * cp = current_task->stack_bottom;

   while (--cp >= (char *)&end_text)   *cp = ' ';
}
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//
//   main() is the idle task. main() MUST NOT BLOCK, but could do
//   some non-blocking background jobs. It is safer, though, to do
//   nothing in main()'s for() loop.
//
int main()
{
int i;
int j;
int k;
j=1;

   //init_unused();
   //init_stack();

   ASM(" MOVE #0x00, RR");            // disable all interrupt sources
   ASM(" OUT  R, (OUT_INT_MASK)");

   // we dont know the value of the interrupt disable counter,
   // so we force it to zero (i.e. interrupts enabled)
   //
   for (i = 0; i < 16; ++i)   ASM(" EI");   // decrement int disable counter

   //ASM(" MOVE #0x05, RR");            // enable Rx and timer interrupts
   ASM(" MOVE #0x04, RR");            // enable Rx and timer interrupts
   ASM(" OUT  R, (OUT_INT_MASK)");
   
  //adr_ex_mem	= 65472;//0xFFBE 
  //adr_dct		= 8193;//0x2001
  //fix_int       = 6000;
  //hack = 0;
  //base_adr		= 0x13E0;
  //*(base_adr)   = 65470;
  ASM(" MOVE #0xFFBE, RR;
	    MOVE RR, (0x13E0);");
  //ASM (" MOVE #0xFFBD,RR ");
  //ASM (" MOVE #0x2002,LL ");
 
  for (;;) 
  {
    if( flag == 0)  // Gating logic to prevent writes when DCT is busy (output has not been read out)
		{
   		 
//		 	for (i = 0; i < 65; ++i)
//   		 	{
//			   if ( i == 0 )
//			   {
//					*(fix_int) = *(adr_ex_mem+i);
//				   // hack = 1;
//			   }
//				else
//				{
//					*(adr_dct) = *(adr_ex_mem+i);
//				}

//			}	

// ******** Assembly subroutine to pull input data for the DCT from the external memory to the internal memory  *******////
// ******** and transfer internal memory data to the DCT over the processors wishbone interface.                *******////
// ******** Different address locations in internal memory 0x13E0 0x13FF, 0x13FD were used to hold the values   *******////
// ******** of different counters.  *******////

		ASM("   NOP ;
			    NOP ;
			    NOP ;
				
			    MOVE (0x13E0), RR ;		Address location of first input value
				MOVE #0x1401, LL ;		Address location where input values will begin to be stored 

				LoopEXTINT:
					        MOVE (RR)+, (LL)+ ;
				    		JMP RRNZ, LoopEXTINT;

				; Now write these to the DCT Core

				 MOVE #0x003F, RR  ;    (192, or 256-64) End of loop condition checking
				 MOVE RR, (0x13FF) ;
				 MOVE #0x1402, RR  ;	   Address location of first input value in internal memory
				 MOVE RR, (0x13FD) ;

				 LoopINTDCT:

							MOVE (0x13FD), RR ;
							MOVE #0x2002, LL ; To write to the DCT, use this address
							MOVE (RR)+, (LL)+ ;
						    MOVE RR, (0x13FD) ; Save RR's state
							MOVE (0x13FF), RR ; Now to check for end of loop condition
							SUB RR, #0x0001 ;
							MOVE RR, (0x13FF) ;
							JMP RRNZ, LoopINTDCT ;

				 MOVE (0x13FD), RR ;
				 SUB RR, #0x0001 ;
				 MOVE (RR), RR ;
				 MOVE RR, (0x2002) ;
				 NOP;
				 NOP;
				 NOP;
				 NOP;
				 NOP;
				 NOP;
				 NOP;
				 NOP;
				 NOP;
				 NOP;
				 NOP;
			 NOP;	
				 MOVE	(0x13E0), RR;
				 ADD	RR, #0x0040;
				 MOVE	RR, (0x13E0);

			 ");
			 //*(base_adr) = *(base_adr) + 64;
		  flag = 1; // Set flag, which prevents further writes to DCT until output has been read
   		}
  } 
   
   
   //if(j==10)   ASM(" HALT");
   //current_task->next_task->status = TASK_RUNNING;  
   //deschedule();


}


//-----------------------------------------------------------------------------
//----- Task to read the output from the DCT and store it in memory ----------
//----- at a CONFIGURABLE location

int main_1(int argc, char * argv[])
{
int             c;
int             i;
char            last_c;
unsigned char * address;
int             value;

   ASM(" EI");

   //init_stack();
   value =100;

   ASM(" MOVE #0x04, RR");            // enable Rx and timer interrupts
   ASM(" OUT  R, (OUT_INT_MASK)");
   //adr_ex_dct	= 0x13E2;//0x3000
   //*(adr_ex_dct) = 12288;
   ASM(" MOVE #0x3000, RR;
	     MOVE RR, (0x13E2);");
   for (;;)
    {
      if( (flag==1) && (flag2 == 0) ) // Gating logic to allow read AFTER all data has been written to DCT, and before tiling can be done
	{                               // prevents processor hanging in case of reading from DCT if all 64 input data haven't been written
//   		for (i = 0; i < 128; ++i)
//		{ This code did not work due to address offset issues after compiling
//   		  *(adr_ex_dct+i) = *adr_dct;
//   		}

// *******  Assembly subroutine to read 128 values (12 bit extended to 16 bit, for 64 data) from the DCT and store them at a specified 
// ******   Configurable memory location for 4x4 and 2x2 tiling, and retrieval	
	ASM("   
				MOVE (0x2001), LL   ; dummy operation. We will be missing the last output
				MOVE #0x0040, RR	; 128 values to be read and RR decremented by one
				MOVE RR, (0x13FF)	;
				MOVE (0x13E2), RR    ; Move starting address of output data RECONFIGURABLE
				MOVE RR, (0x13FD) ; 
				SUB RR, #0x0001 ;
				MOVE RR, (0x13FB) ;  This shall be used later, when doing 4x4
				MOVE RR, (0x13F0) ;  When doing 2x2


				LoopDCTEXT:		; 	Move data from DCT to external memory

					MOVE (0x2001), LL ; To read from DCT
					MOVE (0x13FD), RR ; 
					MOVE LL, (RR) 	; To write to external memory - This shall copy all 16 bits 8 at a time
					ADD RR, #0x0002 ;
					MOVE RR, (0x13FD) ;
					MOVE (0x13FF), RR ;
					SUB RR, #0x0001 ;
					MOVE RR, (0x13FF) ;
					JMP RRNZ, LoopDCTEXT ;

				MOVE	(0x13E2), RR;
				ADD	RR, #0x0080;
				MOVE	RR, (0x13E2);

			  ");
	  //*(adr_ex_dct) = *(adr_ex_dct) + 128; // Did not work due to address offset issues in compiled code
	  flag = 0; // Clear the flag to allow next 64 data to be written to DCT core
	    flag2 = 1;  // Set flag2 to allow tiling code to execute
	   }
   
    }

}


//-----------------------------------------------------------------------------
//--- Tiling task: Create tiles of 4x4 and 2x2 from the DCT output ------------
//----------------------------------------------------------------------------

void main_2()
{
unsigned int all_value;
unsigned int halt_value;
unsigned int all_total;
unsigned int halt_total;
int n;
int idle;

   ASM(" EI");

   //init_stack();
 

   for (;;)
       {
	 if (flag2 == 1) // Gating logic to prevent tiling before DCT output is read.
		{
			ASM("MOVE (0x13E2), RR
				MOVE RR, (0x13FD); ");
			  
			// Code to deal with the tiles.
			ASM("	NOP ;
			   	    NOP ;
					NOP ;
					NOP ;
					NOP ;
					NOP ;
				   
			  ; Now for the easy part!!! 4x4 tiles

			  MOVE (0x13FD), RR ; leave a memory space
			  ADD RR, #0x0001 ;
			  MOVE RR, (0x13FD) ;
			  MOVE #0x0004, RR ;
			  MOVE RR, (0x13FF) ;  Counter for columns
			  MOVE #0x0008, RR ;
			  MOVE RR, (0x13F9) ; Counter for rows

			  ;13FF contains 4 and 13F9 contains 8

			  LoopCol:		; Writing 4x4 tile to external memory

			  LoopRow:

				MOVE (0x13FB), RR ; Address to read from 
				MOVE (RR), RR ; 
				MOVE (0x13FD), LL ; Address to write to
				LSR  RR, #0x0008  ; Shift, so that we write lower 8 bits.
				MOVE R, (LL)      ; Write only lower 8 bits This part is ok, it work
				MOVE LL, RR 	  ;
				ADD RR, #0x0001	  ;
				MOVE RR, (0x13FD) ; Store updated write address
				MOVE (0x13FB), RR ;
				ADD RR, #0x0001   ;
				MOVE RR, (0x13FB) ;
				MOVE (0x13F9), RR ;  
				SUB RR, #0x0001   ;
				MOVE RR, (0x13F9) ;

				JMP RRNZ, LoopRow ;  So after 8 times, we have copied 4 rows of one column

				MOVE #0x0008, RR  ;
				MOVE RR, (0x13F9) ;
				MOVE (0x13FB), RR ;
				ADD RR, #0x0008	  ;
				MOVE RR, (0x13FB) ; 
				MOVE (0x13FF), RR ;
				SUB RR, #0x0001   ;
				MOVE RR, (0x13FF) ;

				JMP RRNZ, LoopCol ;  So after 4 times, we have copied the 4x4


				; Now for the easy part!!! 2x2 tiles

	   		  MOVE (0x13FD), RR ;
			  ADD RR, #0x0001 ;
			  MOVE RR, (0x13FD) ; Leave a memory space
			  MOVE #0x0002, RR ;
			  MOVE RR, (0x13FF) ;  Counter for columns
			  MOVE #0x0004, RR ;
			  MOVE RR, (0x13F9) ; Counter for rows

			  ; 13FF contains 2 and 13F9 contains 4

			  LoopColalt:		; Writing 4x4 tile to external memory

			  LoopRowalt:

				MOVE (0x13F0), RR ; Address to read from 
				MOVE (RR), RR ; 
				MOVE (0x13FD), LL ; Address to write to
				LSR  RR, #0x0008  ; Shift, so that we write lower 8 bits.
				MOVE R, (LL)      ; Write only lower 8 bits This part is ok, it work
				MOVE LL, RR 	  ;
				ADD RR, #0x0001	  ;
				MOVE RR, (0x13FD) ; Store updated write address
				MOVE (0x13F0), RR ;
				ADD RR, #0x0001   ;
				MOVE RR, (0x13F0) ;
				MOVE (0x13F9), RR ;  
				SUB RR, #0x0001   ;
				MOVE RR, (0x13F9) ;

				JMP RRNZ, LoopRowalt ;  So after 4 times, we have copied 2 rows of one column

				MOVE #0x0004, RR  ;
				MOVE RR, (0x13F9) ;
				MOVE (0x13F0), RR ;
				ADD RR, #0x000C	  ; Add 12
				MOVE RR, (0x13F0) ; 
				MOVE (0x13FF), RR ;
				SUB RR, #0x0001   ;
				MOVE RR, (0x13FF) ;

				JMP RRNZ, LoopColalt ;  So after 2 times, we have copied the 2x2
				
				NOP;
				MOVE (0x13FD),RR;
				MOVE RR, (0x13E2);
					");
			flag2 = 0;

			}

       }
}
//-----------------------------------------------------------------------------
void main_3()
{
char out;

   ASM(" EI");

   //init_stack();

   for (;;)
       {
         P(&t3_control);
         //V(&t3_control);

         //P(&serial_out);
         //for (out = '0'; out <= '9'; ++out)   putchr(out);
         //for (out = 'A'; out <= 'Z'; ++out)   putchr(out);
         //for (out = 'a'; out <= 'z'; ++out)   putchr(out);
         //putchr('\r');
         //putchr('\n');
         //V(&serial_out);
       }
}
//-----------------------------------------------------------------------------
//
// task stacks
//
unsigned int stack_1[200], tos_1[3] = { 0, 0, (int)&main_1 }, top_1[0];
unsigned int stack_2[200], tos_2[3] = { 0, 0, (int)&main_2 }, top_2[0];
unsigned int stack_3[200], tos_3[3] = { 0, 0, (int)&main_3 }, top_3[0];

Task task_3 =    { &task_idle,         // next task
                   tos_3,              // current stack pointer
                   TASK_RUNNING,       // current state
                   30 ,                // priority
                   "Load Task ",       // task name
                   (char *)&stack_3,   // bottom of stack
                   (char *)&top_3 };   // top    of stack

//Task task_2 =    { &task_3,            // next task
Task task_2 =    { &task_idle,            // next task
                   tos_2,              // current stack pointer
                   TASK_RUNNING,       // current state
                   30 ,                // priority
                   "Measurement",      // task name
                   (char *)&stack_2,   // bottom of stack
                   (char *)&top_2 };   // top    of stack

Task task_1 =    { &task_2,            // next task
//Task task_1 =    { &task_idle,            // next task
                   tos_1,              // current stack pointer
                   TASK_RUNNING,       // current state
                   50,                 // priority
                   "Monitor",          // task name
                   (char *)&stack_1,   // bottom of stack
                   (char *)&top_1 };   // top    of stack

Task task_idle = { &task_1,        // next task
                   0,              // current stack pointer (N/A since running)
                   TASK_RUNNING,   // current state
                   70,              // priority
                   "Idle Task",    // task name
                   (char *)0x1F80,         // bottom of stack
                   (char *)0x2000 };       // top    of stack

Task * current_task = &task_idle;

//-----------------------------------------------------------------------------
