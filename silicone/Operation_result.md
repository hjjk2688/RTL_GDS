# Manual Mode 

## Case 1.

<img width="466" height="358" alt="image" src="https://github.com/user-attachments/assets/0c7d949a-e9ae-4f56-a514-1cb39b77774e" />

* Input A = 0001 (1) / Input B = 0011(3)
* op_code = 000 ( + , add)
* result = 1 + 3 = 0100 (4)

### YAT 프로그램 사용 하여 UART 통신 결과 확인
<img width="711" height="66" alt="image" src="https://github.com/user-attachments/assets/cc41e74b-f6b9-4a9c-b203-bef143a6bcc7" />

* result = 1 + 3 = 0100 (4)

## Case 2.

<img width="505" height="379" alt="image" src="https://github.com/user-attachments/assets/0d500b27-9656-407c-a3ac-079cff8b32b0" />

* Input A = 0101 (5) / Input B = 0011(3)
* op_code = 100 ( % , mod)
* result = 5 % 2 = 0010 (2)
  
### YAT 프로그램 사용 하여 UART 통신 결과 확인
<img width="707" height="62" alt="image" src="https://github.com/user-attachments/assets/a5d63fe6-aca7-47ad-9122-29e489e16b38" />

* result = 5 % 2 = 0010 (2)
--------
# CPU Mode
## register 
```verilog
  4'd0: instr_out_reg = 8'b11000101; // "LDI R0, 5"
  4'd1: instr_out_reg = 8'b00000001; //  +1 110
  4'd2: instr_out_reg = 8'b00000001; //  +1  111
  4'd3: instr_out_reg = 8'b00000001; //  +1 1000
  default: instr_out_reg = 8'b00000000; // Default to NOP

```

## 결과

<img width="531" height="392" alt="image" src="https://github.com/user-attachments/assets/5b376f72-1d2e-4eb2-9e05-ec3de5afc3fe" />

### YAT 프로그램 사용 하여 UART 통신 결과 확인
<img width="707" height="82" alt="image" src="https://github.com/user-attachments/assets/a2504509-12ce-4943-82d8-c25329a006b9" />

* 0101 => 0110 => 0111 => 1000 으로 정상 작동 확인
