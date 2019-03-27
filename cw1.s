@---------------------------------------------------
@ File:     cw1.s
@ Author:   100227789 | 100227220
@---------------------------------------------------

    .data
argerr:     .asciz  "Error: invalid number of arguments\n"

string:     .space  1000    @ space to save input string
indices:    .space  200     @ space to save sorted key indices 
decstr:     .space  1000    @ space to save decrypted string

    .text

    .globl main

@---------------------------------------------------
@ main procedure
@---------------------------------------------------
main:   
    push {lr}           @ save lr on the stack

    ldr  r4, [sp, #8]   @ get the address of the command line argument
    ldr  r0, [sp, #12]  @ get the number of command line arguments

    cmp  r0, #3         @ if the number of arguments is not 3, exit
    bne  error

    ldr r0, [r4, #8]    @ get the private key length
    bl strlen              
    mov r5, r0          @ save length in r5

    ldr r1, =indices    @ save indices for the key chars
    mov r2, #0          @ start in index 0
indloop:
    str r2, [r1], #4    @ save index in array and post increment
    add r2, r2, #1      @ increment index
    cmp r2, r0          @ repeat until we reach the key length
    blt indloop

    ldr r0, [r4, #8]    @ get the private key string pointer
    mov r1, r5          @ get string length 
    ldr r2, =indices    @ get start address of indices
    bl sort             @ sort the key indices using bubble sort

    
    ldr  r0, [r4, #4]   @ get the encrypt/decrypt option
    ldrb r6, [r0]       @ get the first char, should be 0 or 1
   
    ldr r0, =string     @ read the text input from stdin into string buffer
    mov r1, r5          @ pass key length as row size
    bl readstr    

    cmp r6, #'0'        @ if the first command line option is not '0', decrypt
    bne dodecrypt

doencrypt:
    mov r1, r0          @ pass number of rows in r1
    ldr r0, =string     @ pass string to encrypt in r0
    ldr r2, =indices    @ pass indices table 
    mov r3, r5          @ pass number of indices in r3
    bl encrypt          @ encrypt string
    b  endprog

dodecrypt:
    mov r1, r0          @ pass number of rows in r1
    ldr r0, =string     @ pass string to encrypt in r0
    ldr r2, =indices    @ pass indices table 
    mov r3, r5          @ pass number of indices in r3
    bl decrypt          @ decrypt string

endprog:      
    mov r0,#0           @ return code, no errors
    b   return

error:
    ldr r0,=argerr  @ print the error message
    bl printf       
    mov r0,#1       @ return code to indicate error
    
return:
    pop {lr}        @ restore lr from the stack    
    mov pc,lr       @ return to calling function

@---------------------------------------------------
@ strlen: get the length of a string 
@
@ Arguments:    r0 = address of string
@ Returns:      r0 = string length
@---------------------------------------------------
strlen:
    mov  r2, #0         @ r2 will count chars, start in zero
cntloop:
    ldrb r1, [r0], #1   @ load a char from the string, increment pointer
    cmp  r1, #0         @ see if we reached the end of the string
    beq  endcnt         @ if so, end counting
    add  r2, r2, #1     @ else, increment string length
    b    cntloop        @ repeat
endcnt:
    mov  r0, r2         @ return the char count    
    mov  pc, lr         @ return to calling function


@---------------------------------------------------
@ readstr: reads a string from the standard input,
@   strips whitespace and punctuations, changes upper
@   to lowercase chars and adds extra characters 
@   depending on the row size given
@
@ Arguments:    r0 = address of buffer to save string
@               r1 = number of chars in a row (key length)    
@ Returns:      r0 = string length
@---------------------------------------------------
readstr:
    stmfd sp!,{r4-r7, lr}
    mov r4, r0          @ load input buffer address in r4
    mov r5, r1          @ load row length in r5
    mov r6, #0          @ r6 will count the columns
    mov r7, #0          @ r7 will count the rows
readin:
    bl  getchar         @ read a character from stdin
    cmp r0, #0          @ if no more input, stop reading
    ble endread

    cmp r0, #'A'        @ if it's a char between A and Z, transform to lowercase
    blt readin
    cmp r0, #'Z'
    bgt iflow
    add r0, r0, #32     @ convert to lowercase
    b   savechar        @ save the character

iflow:
    cmp r0, #'a'        @ if it's a char between a and z, save
    blt readin
    cmp r0, #'z'
    bgt readin

savechar:
    strb r0, [r4], #1   @ save character in the buffer
    add  r6, r6, #1     @ increment column
    cmp  r6, r5         @ if we reached the key length
    blt  readin
    mov  r6, #0         @ restart column to 0
    add  r7, r7, #1     @ increment row number
    b    readin

endread:
    cmp r6, #0          @ see if we need padding
    beq nopad           @ if not, return

    mov r0, #'x'        @ padding char
padloop:
    strb r0, [r4], #1   @ save character in the buffer
    add  r6, r6, #1     @ increment column
    cmp  r6, r5         @ see if we reached the key length
    blt  padloop        @ if not, repeat
    add  r7, r7, #1     @ increment row number
    
nopad:
    mov r0, r7          @ return number of rows
    ldmfd sp!,{r4-r7, lr}
    mov  pc, lr         @ return to calling function


@---------------------------------------------------
@ sort: sorts the characters in a string and saves the
@   sorted indices in the array given as argument
@
@ Arguments:    r0 = address of string to sort
@               r1 = string length
@               r2 = pointer to array to save sorted 
@                    indices
@---------------------------------------------------
sort:
    stmfd sp!,{r4-r8, lr}
    add r3, r1, #-1     @ save length-1 in r3
    mov r4, #0          @ index i for the loop
l1:    
    mov r5, #0          @ index j for the loop
l2:
    ldrb r6, [r0, r5]   @ load string[j]
    add  r7, r5, #1
    ldrb r8, [r0, r7]   @ load string[j + 1]
    cmp  r6, r8         @ if string[j] <= string[j+1], go to next
    ble  skip
                            
    strb r8, [r0, r5]   @ swap string[j] and string[j+1]
    strb r6, [r0, r7]

    ldr  r6, [r2, r5, lsl #2]   @ swap indices[j] and indices[j+1]
    add  r7, r5, #1
    ldr  r8, [r2, r7, lsl #2]
    str  r8, [r2, r5, lsl #2]
    str  r6, [r2, r7, lsl #2]
skip:
    add r5, r5, #1      @ j++
    cmp r5, r3
    blt l2

    add r4, r4, #1      @ i++
    cmp r4, r1
    blt l1

    ldmfd sp!,{r4-r8, lr}
    mov  pc, lr         @ return to calling function

@---------------------------------------------------
@ encrypt: encrypts a string and prints in standard
@   output
@
@ Arguments:    r0 = string to encrypt
@               r1 = number of rows in string
@               r2 = pointer to array of key indices
@               r3 = number of key indices
@---------------------------------------------------
encrypt:
    stmfd sp!,{r4-r10, lr}

    mov r7, r1          @ save number of rows in r7
    mov r8, r3          @ save number of indices in r8
    mov r9, r0          @ put string address in r9
    mov r10, r2         @ put index address in r10

    mov r4, #0
colloop:
    ldr r6, [r10, r4, lsl #2]   @ get index of column to use
    add r6, r6, r9              @ get start address in string

    mov r5, r7          @ repeat the inner loop the number of rows
rowloop:
    ldrb r0, [r6]       @ load character from string
    
    bl putchar          @ output to stdout

    add r6, r6, r8      @ advance to next row
    subs r5, r5, #1     @ repeat for all rows in string
    bgt  rowloop

    add  r4, r4, #1     @ advance to next column
    cmp  r4, r8         @ repeat for all columnns in key
    blt  colloop

    mov r0, #10         @ print an ending newline
    bl putchar

    ldmfd sp!,{r4-r10, lr}
    mov  pc, lr         @ return to calling function


@---------------------------------------------------
@ decrypt: decrypts a string and prints the result
@   in the standard output
@
@ Arguments:    r0 = string to decrypt
@               r1 = number of rows in string
@               r2 = pointer to array of key indices
@               r3 = number of key indices
@---------------------------------------------------
decrypt:
    stmfd sp!,{r4-r11, lr}

    mov r7, r1          @ save number of rows in r7
    mov r8, r3          @ save number of indices in r8
    mov r9, r0          @ put string address in r9
    mov r10, r2         @ put index address in r10
    ldr r11, =decstr    @ point to decrypt buffer with r11
    mov r4, #0
dcolloop:
    ldr r6, [r10, r4, lsl #2]   @ get index of column to use
    add r6, r6, r11             @ get start address in decrypted string

    mov r5, r7          @ repeat the inner loop the number of rows
drowloop:
    ldrb r0, [r9], #1   @ load character from string
    strb r0, [r6]       @ save in decrypt buffer

    add r6, r6, r8      @ advance to next row
    subs r5, r5, #1     @ repeat for all rows in string
    bgt  drowloop

    add  r4, r4, #1     @ advance to next column
    cmp  r4, r8         @ repeat for all columnns in key
    blt  dcolloop

    ldr r4, =decstr     @ point to decrypt buffer with r4
    mul r5, r7, r8      @ get number of chars in r5 = columns*rows
print:
    ldrb r0, [r4], #1   @ load a character from the decrypted string
    cmp r0, #'x'        @ compare it with the padding character
    beq endprint        @ if equal, end printing
    bl  putchar         @ else, print char on stdout
    subs r5, r5, #1     @ decrement number of characters to print
    bgt  print          @ repeat while not zero
endprint:
    mov r0, #10         @ print an ending newline
    bl putchar
    
    ldmfd sp!,{r4-r11, lr}
    mov  pc, lr         @ return to calling function
