.model small
.386

theStack SEGMENT PARA STACK 'stack' USE16
db 100h DUP(?)
theStack ENDS

data SEGMENT USE16

result db 11 DUP(?)
prompt1 db "Enter first number (-32768..32767): ", '$'
prompt2 db "Enter second number (-32768..32767): ", '$'
maxlen1 db 7
num1_len db 0
num1 db 7 DUP(?)
maxlen2 db 7
num2_len db 0
num2 db 7 DUP(?)
plus_sign db " + ", '$'
equal_sign db " = ", '$'

data ENDS

code SEGMENT USE16
ASSUME CS:code, DS:data, ES:data, SS:theStack

print_newline:
  mov dl, 10
  mov ah, 02h
  int 21h
  ret

; Convert 32-bit integer to string
; Args:
;   eax - 32-bit integer
;   edi - address of the buffer
; Return:
;   eax - length of the string 
;   edi - address of the string
int_to_str:
  push bp
  mov bp, sp
  push ebx
  push ecx
  push edx
  push edi

  mov ebx, 10             ; Store divider in ebx
  xor ecx, ecx            ; Initialize counter

  cmp eax, 0
  jge .push_digits

  ; Handle negative number
  mov edx, eax            ; Save eax
  mov eax, '-'
  stosb
  mov eax, edx            ; Restore eax
  neg eax

.push_digits:
  xor edx, edx
  div ebx                 ; Divide by 10
  add edx, 30h            ; Convert digit to ASCII char
  push edx
  inc ecx
  test eax, eax
  jnz .push_digits

.pop_digits:
  pop eax
  stosb                   ; Write char to the buffer
  dec ecx
  test ecx, ecx
  jne .pop_digits

  ; Append NULL
  mov eax, '$'
  stosb

  mov eax, edi

  pop edi
  pop edx
  pop ecx
  pop ebx
  mov sp, bp
  pop bp

  ; Return number of bytes
  sub eax, edi
  ret

; Convert string to 32-bit integer
; Args:
;   al - address of the string
; Return:
;   eax - integer
str_to_int:
  push bp
  mov bp, sp
  push ebx
  push ecx
  push edi
  push esi

  mov ebx, 10             ; Store multipler in ebx
  mov ecx, eax            ; Save string address in ecx
  and ecx, 00ffh          ; Cleanup
  xor esi, esi            ; Initialize negative number flag
  xor eax, eax

  ; Handle negative number
  mov edi, [ecx]
  and edi, 00ffh          ; Cleanup
  cmp edi, '-'
  jne .loop
  inc ecx
  mov esi, 1

.loop:
  mov edi, [ecx]
  and edi, 00ffh          ; Cleanup

  ; If we encountered NULL, exit the loop
  cmp edi, '$'
  je .end_loop

  mul ebx
  sub edi, 30h            ; Convert ASCII to digit
  add eax, edi
  inc ecx
  jmp .loop
.end_loop:

  ; Negate number if negative number flag is set
  test esi, esi
  je .finish
  neg eax

.finish:
  pop esi
  pop edi
  pop ecx
  pop ebx
  mov sp, bp
  pop bp
  ret

start:
  ; Initialize data segment
  mov ax, SEG data
  mov ds, ax
  mov es, ax

  ; Print first prompt
  mov ah, 09h
  mov dx, OFFSET prompt1
  int 21h

  ; Read first number
  mov ah, 0ah
  mov dx, OFFSET maxlen1
  int 21h

  call print_newline

  ; Append NULL to the first number
  mov al, num1_len
  cbw                     ; Extend al to ax
  mov si, ax
  mov num1+si, '$'

  ; Print second prompt
  mov ah, 09h
  mov dx, OFFSET prompt2
  int 21h

  ; Read second number
  mov ah, 0ah
  mov dx, OFFSET maxlen2
  int 21h

  call print_newline

  ; Append NULL to the second number
  mov al, num2_len
  cbw                     ; Extend al to ax
  mov si, ax
  mov num2+si, '$'

  ; Convert first number to int
  mov al, OFFSET num1
  call str_to_int
  mov ebx, eax

  ; Convert second number to int
  mov al, OFFSET num2
  call str_to_int

  add eax, ebx

  ; Convert their sum to string
  mov edi, DWORD PTR result
  call int_to_str
  mov ebx, eax

  ; Print first number
  mov ah, 09h
  mov dx, OFFSET num1
  int 21h

  ; Print plus sign
  mov ah, 09h
  mov dx, OFFSET plus_sign
  int 21h

  ; Print second number
  mov ah, 09h
  mov dx, OFFSET num2
  int 21h

  ; Print equal sign
  mov ah, 09h
  mov dx, OFFSET equal_sign
  int 21h

  ; Print the result
  mov ah, 09h
  mov dx, OFFSET result
  int 21h

  call print_newline

  ; Exit with status 0
  mov ah, 4ch
  mov al, 00h
  int 21h

code ENDS

end start
