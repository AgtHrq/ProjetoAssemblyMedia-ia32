.386

.model flat, stdcall
option casemap :none
include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
include \masm32\include\masm32.inc
include \masm32\include\msvcrt.inc
include \masm32\macros\macros.asm
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\masm32.lib
includelib \masm32\lib\msvcrt.lib


;DB - Define Byte. 8 bits
;DW - Define Word. Generally 2 bytes on a typical x86 32-bit system
;DD - Define double word. Generally 4 bytes on a typical x86 32-bit system

;http://www.cs.virginia.edu/~evans/cs216/guides/x86.html


.data

;usados em readConsole
readchar_count dw 0
read_count dw 0

;usado em writeConsole
write_count dw 0

;strings com mensagens
msg_Vazia db " ", 0h
msg_NNotas db "Insira o numero de notas a serem computadas: ", 0ah, 0h
msg_Nota db "Insira a nota a ser computada:", 0ah, 0h
msg_Media db "A media calculada pelas notas inseridas eh: ", 0h
msg_Reprovacao db "O aluno com as notas inseridas foi reprovado.", 0ah, 0h
msg_Aprovado db "O aluno com as notas inseridas foi aprovado", 0ah, 0h
msg_ProvaFinal db "O aluno com as notas inseridas tera que fazer a prova final e precisara de: ", 0h
msg_RepetirOperacao db "Deseja inserir novas notas e calcular a media?", 0ah, 0h
msg_Sim db "s"

;strings usadas para salvar info
string_Nota db 10 dup(?)
string_NNotas db 10 dup(?)
string_Resultado db 4 dup(?)
string_Media db 4 dup(?)
string_Final db 4 dup(?)
string_Operacao db 3 dup(?)

;variavéis para salvar info das notas
valor_Nnotas dd ?
valor_Media real8 ?
valor_Final real8 ?
array_Notas real8 10 dup(0.0)
valor_carregar real8 ?

;floats usados no calculo da media ponderada
;a media será a Prova final x 4 (o seu peso) + a media x 6 (o seu peso) / 10 (soma dos pesos) vai ser igual a 5 (nota minima necessaria na final)
;4pf + 6m = 50

num_Cinquenta real8 50.0
num_PesoMedia real8 6.0
num_PesoFinal real8 4.0
num_Zero real8 0.0 
num_aprovacao real8 7.0
num_reprovacao real8 4.0

.code

start:

_receberNumDeNotas:

;zera registradores
mov ebx, 0 ;contador em repetições
mov eax, 0 ;usado em operações aritiméticas

;imprime no console a mensagem de inserir n de notas
push STD_OUTPUT_HANDLE
call GetStdHandle
invoke WriteConsole, eax, addr msg_NNotas, sizeof msg_NNotas, addr write_count, NULL

;recebe o n de notas inserido pelo usuario
push STD_INPUT_HANDLE
call GetStdHandle
invoke ReadConsole, eax, addr string_NNotas, sizeof string_NNotas, addr read_count, NULL

;correção do input recebido - no slide do prof

mov esi, offset string_NNotas ;armazena apontador da string em esi
proximo:
mov al, [esi] ;move caracter atual para al
inc esi ;aponta para o proximo caracter
cmp al, 48 ;verifica se menor que ASCII 48 - FINALIZAR
jl terminar
cmp al, 58 ;verificar se menor que ASCII 58 - CONTINUAR
jl proximo
terminar:
dec esi ;aponta para caracter anterior
xor al, al ;0 ou NULL
mov [esi], al ;inserir NULL logo apos o termino do numero

;fim da correção do input recebido

mov eax, 0 ;zera eax para não causar problemas qndo for salvar em ax

invoke atodw, addr string_NNotas ;armazena valor convertido em ax

mov valor_Nnotas, eax ;pega numero de notas

_receberNotas:

;imprime no console msg de inserir as notas
push STD_OUTPUT_HANDLE
call GetStdHandle
invoke WriteConsole, eax, addr msg_Nota, sizeof msg_Nota, addr write_count, NULL

;recebe o input da nota
push STD_INPUT_HANDLE
call GetStdHandle
invoke ReadConsole, eax, addr string_Nota, sizeof string_Nota, addr read_count, NULL ;recebe valor para ser convertido e usado

;converte o input (string) recebido para float
push ebx
invoke StrToFloat, addr string_Nota, addr valor_carregar 
pop ebx

fld valor_carregar                ;carrega valor recebido e convertido
fstp array_Notas[ebx*8]           ;guarda o valor puxado

inc ebx
cmp ebx, valor_Nnotas
jl _receberNotas

_Media:

mov ebx, 0

_PoeNotasNaPilha:

;carrega n nota na pilha
fld array_Notas[ebx*8]

inc ebx
;compara se o loop ja foi feito no num de notas
cmp ebx, valor_Nnotas
jl _PoeNotasNaPilha
dec valor_Nnotas
mov ebx, 0

_adicaoDasNotas:

;instrucao q add os floats na pilha
fadd

;compara se o loop ja foi feito no num de notas
inc ebx
cmp ebx, valor_Nnotas
jl _adicaoDasNotas

inc valor_Nnotas

fild valor_Nnotas

;divide floats na pilha
fdiv 
fstp valor_Media

;converte string para float
push ebx
invoke FloatToStr, valor_Media, addr string_Media 
pop ebx

;imprime no console a msg de media
push STD_OUTPUT_HANDLE
call GetStdHandle
invoke WriteConsole, eax, addr msg_Media, sizeof msg_Media, addr write_count, NULL


;imprime no console o valor da media
push STD_OUTPUT_HANDLE
call GetStdHandle
invoke WriteConsole, eax, addr string_Media, sizeof string_Media, addr write_count, NULL

mov eax, 0

finit                            ;reset fpu stacks to default
fld    valor_Media               ;media to fpu stack
fld    num_aprovacao             ;aprovado to fpu stack (aprovado - media)
fcom                             ;compare st0 with st1
fstsw  ax                        ;ax := fpu status register move o registrador de estado (flags) da fpu para ax

and    eax,  0100000100000000B ;take only condition code flags (zero flag / carry flag)
cmp    eax,  0000000000000000B ;is aprovado (7) > media ? zero flag � 0 pq n sao iguais e carry flag n da 1 pq a subtra��o � positiva
je     _TesteDeReprovacao


;imprime no console msg de aprovacao
push STD_OUTPUT_HANDLE
call GetStdHandle
invoke WriteConsole, eax, addr msg_Aprovado, sizeof msg_Aprovado, addr write_count, NULL

jmp _LoopDeOperacao

_TesteDeReprovacao:

mov eax, 0

finit                            ;reset fpu stacks to default
fld    valor_Media               ;media to fpu stack
fld    num_reprovacao            ;aprovado to fpu stack (aprovado - media)
fcom                             ;compare st0 with st1
fstsw  ax                        ;ax := fpu status register move o registrador de estado (flags) da fpu para ax

and    eax,  0100000100000000B ;take only condition code flags (zero flag / carry flag)
cmp    eax,  0000000000000000B ;is reprovado (4) > media ? zero flag � 0 pq n sao iguais e carry flag n da 1 pq a subtra��o � positiva
je     _MensagemDeReprovacao

finit
fld num_Cinquenta     
fld valor_Media
fld num_PesoMedia
fmul
fsub
fld num_PesoFinal
fdiv
fstp valor_Final

push ebx
invoke FloatToStr, valor_Final, addr string_Final
pop ebx

push STD_OUTPUT_HANDLE
call GetStdHandle
invoke WriteConsole, eax, addr msg_ProvaFinal, sizeof msg_ProvaFinal, addr write_count, NULL

push STD_OUTPUT_HANDLE
call GetStdHandle
invoke WriteConsole, eax, addr string_Final, sizeof string_Final, addr write_count, NULL 

jmp _LoopDeOperacao

_MensagemDeReprovacao:

push STD_OUTPUT_HANDLE
call GetStdHandle
invoke WriteConsole, eax, addr msg_Reprovacao, sizeof msg_Reprovacao, addr write_count, NULL

_LoopDeOperacao:

push STD_OUTPUT_HANDLE
call GetStdHandle
invoke WriteConsole, eax, addr msg_Vazia, sizeof msg_Vazia, addr write_count, NULL 

push STD_OUTPUT_HANDLE
call GetStdHandle
invoke WriteConsole, eax, addr msg_RepetirOperacao, sizeof msg_RepetirOperacao, addr write_count, NULL 

push STD_INPUT_HANDLE
call GetStdHandle
invoke ReadConsole, eax, addr string_Operacao, sizeof string_Operacao, addr readchar_count, NULL

mov al, string_Operacao

cmp al, msg_Sim

je start

_endprog:
invoke ExitProcess, 0

end start
