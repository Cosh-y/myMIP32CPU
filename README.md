# myMIPS32CPU
这是一个满足MIPS32指令集架构的经典五级流水线CPU。
## Implemented instructions
* add, addu, addi, addiu, sub, subu, lui, slt, slti, sltu, sltiu
* lw, lh, lb, lhu, lbu, sw, sh, sb
* beq, bne, j, jal, jr, bgez, bgtz, blez, bltz, bgezal, bltzal, jalr
* AND, OR, andi, ori, NOR, XOR, xori
* sllv, sll, srav, sra, srlv, srl
* mult, multu, div, divu, mflo, mfhi, mtlo, mthi
* mfc0, mtc0, eret, syscall, BREAK, nop
## 支持基本的中断异常。
## 第二次提交增加了流水级之间的握手
## 第三次提交实现了类SRAM接口
## 第四次提交利用AXI接口，加入了Cache模块，Cache与CPU的交互是基于类SRAM接口的，AXI接口由AXI转接桥封装
