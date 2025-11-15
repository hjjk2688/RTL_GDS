## register 
```verilog
  4'd0: instr_out_reg = 8'b11000101; // "LDI R0, 5"
  4'd1: instr_out_reg = 8'b00000001; //  +1 110
  4'd2: instr_out_reg = 8'b00000001; //  +1  111
  4'd3: instr_out_reg = 8'b00000001; //  +1 1000
  default: instr_out_reg = 8'b00000000; // Default to NOP

```

## 결과

<img width="728" height="533" alt="image" src="https://github.com/user-attachments/assets/878fdba7-9cf3-4a23-ab87-d6d16efb9206" />

* YAT 프로그램 사용 하여 UART 통신 결과 확인
* 0101 => 0110 => 0111 => 1000 으로 정상 작동 확인
