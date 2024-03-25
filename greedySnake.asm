.386
.MODEL flat,stdcall
option casemap:none


include windows.inc
include user32.inc
include kernel32.inc
includelib	user32.lib
includelib kernel32.lib
includelib msvcrt.lib

printf		PROTO C :ptr sbyte,	:VARARG 
system		PROTO C :DWORD
srand		PROTO C :DWORD
time		PROTO C :DWORD
rand		PROTO C
free		PROTO C :DWORD
malloc		PROTO C :DWORD

_kbhit		PROTO C
_getch		PROTO C


NULL equ 0

;struct
snake struct
x       DWORD   ?
y       DWORD   ?
next    DWORD   0
snake ends

FOOD struct
x       DWORD   ?
y       DWORD   ?
FOOD ends

.data

;global
head DD 0

click	DD 0h
up		DD 0e048h
down	DD 0e050h
left	DD 0e04bh
right	DD 0e04dh

playerName	DB "test",0
score	DD 0
speed	DD 0

X_MAX	DD		56
Y_MAX	DD		26
sizeof_SS DD	12

.data?
food FOOD <>

.const
; data for print
msgSnake	byte	"■",0
msgDelete	byte	"  ",0
msgFood		BYTE	"⊙", 0
strDecimal DB "%d",0ah,0

;data for system
sys0		byte	"color 0B", 0
sys			byte	"cls",0
sys2		byte	"pause",0

; data for welcome
welcomeOut	byte	"hello %s ,Welcome To Play", 0ah, 0
scoreOut	byte	"Your Score Is:%d    =￣ω￣= ", 0ah, 0
createdOut	byte	"This Game Is Created By JOKER", 0ah, 0

; data for End()
scoreOut1	byte	"/**********************************************/",0
scoreOut2   byte	"GAME   OVER      o(*￣▽￣*)o",0
scoreOut3   byte    "Your Score is %d    hiahiahia",0
scoreOut4   byte    "还不错哦，     继续努力O(∩_∩)O",0

.code
creatgraph	proto	
gotoxy		proto	x:dword,y:dword
gotoprint	proto,	x:dword,y:dword
gotodelete	proto,	x:dword,y:dword


ClickControl	proto
MovingBody	proto
createfood	proto
Eating		proto
ChangeBody	proto x:DWORD, y:DWORD
Judge		proto
Finish      proto

main PROC
	invoke system, offset sys0
	invoke creatgraph
	invoke createfood
	invoke ClickControl
	cmp eax, 0
	jz GameOver
GameOver:
	invoke ExitProcess, 0
	;ret
main ENDP


;--------------------------------
;	int ClickControl(void)
;	if eax == 0, game over
;--------------------------------
ClickControl	proc
				local @clickNew:DWORD
beginWhile:
				invoke	Judge
				cmp		EAX, 0
				je		L1	

				invoke	_kbhit
				cmp		EAX, 0
				je		L2
				invoke	_getch
				mov		@clickNew, EAX
				SAL		@clickNew, 8
				invoke	_getch
				add		@clickNew, EAX
				mov		EAX, click
				XOR		EAX, @clickNew
				AND		EAX, 1
				;cmp		EAX, 1
				je		L2
				mov		EAX, @clickNew
				mov		click, EAX

L2:
				invoke	MovingBody
				invoke	Eating
				jmp		beginWhile
				;mov eax, 0
				;ret
L1:
				mov eax, 0
				ret

ClickControl	endp


;--------------------------------
;	void MovingBody(void)
;--------------------------------
MovingBody proc USES ebx edx
	local x,y,p:dword
	mov eax, dword ptr head
	mov p, eax
	mov edx, [eax]
	mov x, edx
	mov edx, [eax + 4]
	mov y, edx

	xor eax, eax
	mov ebx, p
beginwhile:
	cmp [ebx+8], eax	;eax = 0
	jz	endwhile
	mov ebx, [ebx+8]
	jmp beginwhile

endwhile:
	mov p, ebx
	; 消除尾结点
	
	invoke gotodelete, dword ptr [ebx], dword ptr [ebx+4]

	;switch(click)
	mov ebx, click
	cmp ebx, up
	jne casedown
;case up:
	mov eax, 1
	sub y, eax
	jmp endswitch

casedown:

	cmp ebx, down
	jne caseleft
	mov eax, 1
	add y, eax
	jmp endswitch

caseleft:
	
	cmp ebx, left
	jne caseright
	mov eax, 2
	sub x, eax
	jmp endswitch

caseright:

	cmp ebx, right
	jne endswitch	;break
	mov eax, 2
	add x, eax

endswitch:
	
	mov eax, head
	mov eax, dword ptr [eax]
	cmp x, eax
	jne change
	mov eax, head
	mov eax, dword ptr [eax+4]
	cmp y, eax
	je  nochange
change:
	invoke ChangeBody, x, y

nochange:
	mov ebx, head
	invoke gotoprint, dword ptr [ebx], dword ptr [ebx+4]

	; Control Speed
	mov eax, score
	cmp eax, 100
	jg  above100
	mov ebx, 150
	mov speed, ebx
	jmp endspeedif

above100:
	
	cmp eax,200
	jg  above200
	mov ebx, 100
	mov speed, ebx
	jmp endspeedif

above200:

	cmp eax, 400
	jg  above400
	mov ebx, 50
	mov speed, ebx
	jmp endspeedif

above400:
	
	mov ebx, 10
	mov speed, ebx

endspeedif:
	
	invoke Sleep, dword ptr speed

	ret
MovingBody endp

;--------------------------------
;	void createFood(void)
;--------------------------------
createfood		proc USES ebx edx
				local @flag:BYTE
				
				mov @flag, 0
beginWhile:
				cmp		@flag, 0
				jne		endWhile

				mov		@flag, 1

				invoke time, NULL
				invoke srand, eax

				; food.y = rand() % (25 - 1 + 1) + 1
				invoke rand
				mov		ebx, 25	; (25-1+1)
				xor		edx, edx
				div		ebx
				add		edx, 1	
				mov		food.y, edx

				; food.x = rand() % (54 - 2 + 1) + 2;
				invoke rand
				mov		ebx, 53	; (54-2+1)
				xor		edx, edx
				div		ebx
				add		edx, 2
				mov		food.x, edx

				mov		eax, food.x
				mov		ebx, 2
				xor		edx, edx
				div		ebx
				cmp		edx, 0
				jz		L1
				add		food.x, 1
L1:			
				mov		eax, head
				;mov		judge, eax

beginWhile2:
				mov		edx, [eax+8]
				cmp		edx, 0
				jz		endWhile2
				mov		edx, [eax]
				cmp		food.x, edx
				jne		L2
				mov		edx, [eax+4]
				cmp		food.y, edx
				jne		L2
				mov		@flag, 0

L2:
				mov		eax, [eax+8]
				jmp		beginWhile2

endWhile2:
				jmp		beginWhile

endWhile:	
				invoke gotoxy, food.x, food.y
				invoke printf, offset msgFood

				ret
createfood		endp

;--------------------------------
;	void Eating(void)
;--------------------------------
Eating proc USES ebx

	local new,p:dword

	mov eax, food.x		;food 不是指针
	mov ebx, dword ptr head
	mov ebx, [ebx]
	cmp ebx, eax
	jne endfunc
	mov eax, food.y
	mov ebx, dword ptr head
	mov ebx, [ebx+4]
	cmp ebx, eax
	jnz endfunc
	invoke createfood

	invoke malloc, sizeof_SS
	mov new, eax

	mov eax, head
beginwhile:

	mov ebx, dword ptr [eax+8]
	cmp ebx, 0
	jz  endwhile
	mov eax, [eax+8]
	jmp beginwhile

endwhile:
	
	;leap->next = new; new->next = NULL
	mov ebx, new
	mov [eax+8], ebx
	xor eax, eax
	mov dword ptr [ebx+8], eax

	mov eax, 10
	add score, eax
	invoke gotoxy, 77, 15
	invoke printf, offset strDecimal, score

endfunc:
	ret

Eating endp

;--------------------------------
;	void ChangeBody(int x, int y)
;--------------------------------
ChangeBody proc USES ebx edx, x:DWORD, y:DWORD
	local  @pTemp:DWORD, @new_head:DWORD

	mov ebx, head
	mov @pTemp, ebx
FindLeap:
	mov edx, DWORD ptr[ebx+8]
	cmp edx, NULL
	jz FindLeapEnd
	mov @pTemp, ebx
	mov ebx, [ebx+8]
	jmp FindLeap

FindLeapEnd:
	;if head == leap, jump to end?
	.IF(@pTemp == ebx)
		jmp theEND
	.ENDIF

	mov ebx, @pTemp
	;add ebx, 8
	invoke free, dword ptr[ebx+8]
	mov edx, NULL
	mov [ebx+8], edx
	invoke malloc, sizeof_SS
	mov edx, x
	mov [eax], edx
	mov edx, y
	mov [eax+4], edx
	mov edx, head
	mov [eax+8], edx
	mov head, eax

theEND:
	ret
ChangeBody endp

;--------------------------------
;	int Judge(void)
;	if eax == 0, game over
;--------------------------------
Judge proc USES ebx edx
	local @p:DWORD, @head_x:DWORD, @head_y:DWORD
	mov ebx, head
	mov edx, [ebx]
	mov @head_x, edx
	mov eax, [ebx+4]
	mov @head_y, eax
	.IF(edx <= 0 || edx >= X_MAX || eax <= 0 || eax >= Y_MAX)
		invoke Finish
		mov eax, 0
		ret
	.ENDIF

	mov ebx, head
	mov ebx, [ebx+8]
Check:
	cmp ebx, NULL
	jz Con
	mov edx, [ebx]
	mov eax, [ebx+4]
	.IF(edx == @head_x && eax == @head_y)
		jz Over
	.ENDIF
	mov ebx, [ebx+8]
	jmp Check

Over:
	invoke Finish
	mov eax, 0
	ret
Con:
	mov eax, 1
	ret
Judge endp



;--------------------------------
;	void creatgraph(void)
;--------------------------------
creatgraph	proc	USES ebx ecx edx
			local	@i:dword
			local	@p:dword
			local	@q:dword
			xor		ecx, ecx
buloop1:
			cmp		ecx,58
			jnl		buloop1end
			invoke	gotoprint,ecx,0
			invoke	gotoprint,ecx,26
			add		ecx,2
			jmp		buloop1

buloop1end:

			mov		ecx,1
buloop2:
			cmp		ecx,26
			jnl		buloop2end
			invoke	gotoprint,0,ecx
			invoke	gotoprint,56,ecx
			INC		ecx
			jmp		buloop2

buloop2end:
			;pusha
			invoke	gotoxy,63,10
			invoke	printf, offset welcomeOut, offset playerName
			invoke	gotoxy,63,15
			invoke	printf,offset scoreOut, score
			invoke	gotoxy,63,20
			invoke	printf,offset createdOut
			;popa

			invoke	malloc,sizeof_SS
			mov		head,eax
			mov		edx, 16
			mov		[eax], edx
			mov		edx, 15
			mov		[eax+4], edx

			invoke	malloc,sizeof_SS
			mov	 @p,eax
			mov edx, 16
			mov [eax], edx
			mov [eax+4], edx

			invoke	malloc,sizeof_SS
			mov  @q,eax
			mov	 edx, 16
			mov [eax], edx
			mov edx, 17
			mov [eax+4], edx
			
			mov		edx, @p
			mov		ebx, head
			mov		[ebx+8],edx

			mov		edx, @q
			mov		ebx, @p
			mov		[ebx+8],edx

			mov		edx, NULL
			mov		ebx, @q
			mov		[ebx+8],edx

			ret

creatgraph	endp

;--------------------------------
;	int gotoxy(int x, int y)
;	if eax == 1 => x or y overflow
;--------------------------------
gotoxy		proc	USES ecx,	x:dword,y:dword
			local	@pos:COORD
			local   @hOutput:HANDLE
			local	@cursor:CONSOLE_CURSOR_INFO
			;test
			mov eax, x
			and eax, 0ff00h
			jnz xyErr
			mov eax, y
			and eax, 0ff00h
			jnz xyErr

			; refresh pos of cursor
			invoke  GetStdHandle,STD_OUTPUT_HANDLE
			mov		@hOutput,eax
			mov		eax,x
			mov		ecx,y
			mov     @pos.x,ax
			mov     @pos.y,cx
			invoke	SetConsoleCursorPosition,dword ptr @hOutput,dword ptr @pos

			; hide cursor
			mov		@cursor.bVisible, 0
			mov		@cursor.dwSize, sizeof @cursor
			invoke	SetConsoleCursorInfo,@hOutput,addr @cursor
			xor eax, eax
			ret
		xyErr:
			mov eax, 1
			ret
gotoxy	endp

;--------------------------------
;	print
;--------------------------------

gotoprint	proc,	x:dword,y:dword
	invoke gotoxy, x, y
	pusha
	invoke printf, offset msgSnake
	popa
	ret
gotoprint endp

gotodelete proc,	x:dword,y:dword
	invoke gotoxy, x, y
	pusha
	invoke printf, offset msgDelete
	popa
	ret
gotodelete endp



;--------------------------------
;	void Finish(void)
;--------------------------------
Finish      proc
            local @p:dword, @q:dword

            invoke system, addr sys
            invoke	gotoxy,15,10
			invoke	printf,offset scoreOut1
            invoke	gotoxy,15,20
            invoke	printf,offset scoreOut1
            invoke	gotoxy,18,14
            invoke	printf,offset scoreOut2
            invoke	gotoxy,20,16
            invoke	printf,offset scoreOut3, offset score
            invoke	gotoxy,18,18
            invoke	printf,offset scoreOut4
            
            mov     eax, head            ;p = head ; head、p、q都是指针
	        mov     @p, eax
	        xor     eax, eax

beginwhile:

            mov     eax, @p               ;p == NULL jump
	        cmp     eax, 0
            jz      endwhile

            ;q = p->next
            mov     edx, [eax+8]
            mov     @q, edx

            ;free(p)             
            invoke	free, @p

            ;p = q
            mov     eax, @q              
	        mov     @p, eax
	        xor     eax, eax

            jmp beginwhile

endwhile:

            invoke system, addr sys2
            xor eax, eax
            ret
Finish	endp

END main
