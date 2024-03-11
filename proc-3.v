module proc(DIN, Resetn, Clock, Run, DOUT, ADDR, W);
    input [15:0] DIN;
    input Resetn, Clock, Run;
    output wire [15:0] DOUT;
    output wire [15:0] ADDR;
    output wire W;

    wire [0:7] R_in; // r0, ..., r7 register enables
	wire c, n, z;
	reg cout;
	wire [2:0] flag;
    reg rX_in, IR_in, ADDR_in, Done, DOUT_in, A_in, G_in, AddSub, ALU_and, F_in;
    reg [2:0] Tstep_Q, Tstep_D;
    reg [15:0] BusWires;
    reg [3:0] Sel; // BusWires selector
    reg [15:0] Sum;
    wire [2:0] III, rX, rY; // instruction opcode and register operands
    wire [15:0] r0, r1, r2, r3, r4, r5, r6, pc, A;
    wire [15:0] G;
    wire [15:0] IR;
    reg pc_incr;    // used to increment the pc
    reg pc_in;      // used to load the pc
    reg W_D;        // used for write signal
    wire Imm;
   
    assign III = IR[15:13];
    assign Imm = IR[12];
    assign rX = IR[11:9];
    assign rY = IR[2:0];
	 assign c=flag[2];
	 assign n=flag[1];
	 assign z=flag[0];
	 
    dec3to8 decX (rX_in, rX, R_in); // produce r0 - r7 register enables

    parameter T0 = 3'b000, T1 = 3'b001, T2 = 3'b010, T3 = 3'b011, T4 = 3'b100, T5 = 3'b101;

    // Control FSM state table
    always @(Tstep_Q, Run, Done)
        case (Tstep_Q)
            T0: // instruction fetch
                if (~Run) Tstep_D = T0;
                else Tstep_D = T1;
            T1: // wait cycle for synchronous memory
                Tstep_D = T2;
            T2: // this time step stores the instruction word in IR
                Tstep_D = T3;
            T3: if (Done) Tstep_D = T0;
                else Tstep_D = T4;
            T4: if (Done) Tstep_D = T0;
                else Tstep_D = T5;
            T5: // instructions end after this time step
                Tstep_D = T0;
            default: Tstep_D = 3'bxxx;
        endcase

    /* OPCODE format: III M XXX DDDDDDDDD, where 
    *     III = instruction, M = Immediate, XXX = rX. If M = 0, DDDDDDDDD = 000000YYY = rY
    *     If M = 1, DDDDDDDDD = #D is the immediate operand 
    *
    *  III M  Instruction   Description
    *  --- -  -----------   -----------
    *  000 0: mv   rX,rY    rX <- rY
    *  000 1: mv   rX,#D    rX <- D (sign extended)
    *  001 1: mvt  rX,#D    rX <- D << 8
    *  010 0: add  rX,rY    rX <- rX + rY
    *  010 1: add  rX,#D    rX <- rX + D
    *  011 0: sub  rX,rY    rX <- rX - rY
    *  011 1: sub  rX,#D    rX <- rX - D
    *  100 0: ld   rX,[rY]  rX <- [rY]
    *  101 0: st   rX,[rY]  [rY] <- rX
    *  110 0: and  rX,rY    rX <- rX & rY
    *  110 1: and  rX,#D    rX <- rX & D */
    parameter mv = 3'b000, mvt = 3'b001, add = 3'b010, sub = 3'b011, ld = 3'b100, st = 3'b101,
	     and_ = 3'b110, b = 3'b000, beq = 3'b001, bne = 3'b010, bcc = 3'b011, bcs = 3'b100, bpl = 3'b101, bmi = 3'b110;
    // selectors for the BusWires multiplexer
    parameter SEL_R0 = 4'b0000, SEL_R1 = 4'b0001, SEL_R2 = 4'b0010, SEL_R3 = 4'b0011,
        SEL_R4 = 4'b0100, SEL_R5 = 4'b0101, SEL_R6 = 4'b0110, SEL_PC = 4'b0111, SEL_G = 4'b1000,
        SEL_D /* immediate data */ = 4'b1001, SEL_D8 /* immediate data << 8 */ = 4'b1010, 
        SEL_DIN /* data-in from memory */ = 4'b1011;
		

	
    // Control FSM outputs
    always @(*) begin
        // default values for control signals
        rX_in = 1'b0; A_in = 1'b0; G_in = 1'b0; IR_in = 1'b0; DOUT_in = 1'b0; ADDR_in = 1'b0; 
        Sel = 4'bxxxx; AddSub = 1'b0; ALU_and = 1'b0; W_D = 1'b0; Done = 1'b0;
        pc_in = R_in[7] /* default pc enable */; pc_incr = 1'b0; F_in =1'b0;

        case (Tstep_Q)
            T0: begin // fetch the instruction
                Sel = SEL_PC;  // put pc onto the internal bus
                ADDR_in = 1'b1;
                pc_incr = Run; // to increment pc
            end
            T1: // wait cycle for synchronous memory
                ;
            T2: // store instruction on DIN in IR 
                IR_in = 1'b1;
            T3: // define signals in T3
                case (III)
                    mv: begin
                        if (!Imm) Sel = rY;   // mv rX, rY
                        else Sel = SEL_D;     // mv rX, #D
                        rX_in = 1'b1;         // enable the rX register
                        Done = 1'b1;
                    end
                    mvt: begin
                        // ... your code goes here
						if(!Imm) begin
							A_in=1'b1;
							Sel=SEL_PC;
							F_in=1'b0;
						end
						else
							begin
							Sel=SEL_D8;
							rX_in=1'b1;
							Done=1'b1;
						end
                    end
                    add, sub, and_: begin
                        // ... your code goes here
						Sel=rX;
						A_in=1'b1;
						F_in=1'b1;
                    end
                    ld, st: begin
                        // ... your code goes here
						Sel=rY;
						ADDR_in=1'b1;
                    end
                    default: ;
                endcase
            T4: // define signals T2
                case (III)
                    add: begin
                        // ... your code goes here
						if(!Imm) Sel=rY;
						else Sel=SEL_D;
						F_in=1'b1;
						G_in=1'b1;
                    end
					mvt: begin
						if(!Imm) begin 
							Sel = SEL_D;
							G_in=1'b1;
							AddSub=1'b0;
							F_in=1'b0;
							end
					end
                    sub: begin
                        // ... your code goes here
						if(!Imm) Sel=rY;
						else Sel=SEL_D;
						AddSub=1'b1;
						F_in=1'b1;
						G_in=1'b1;
                    end
                    and_: begin
                        // ... your code goes here
						if(!Imm) Sel=rY;
						else Sel=SEL_D;
						ALU_and=1'b1;
						F_in=1'b1;
						G_in=1'b1;
                    end
                    ld: // wait cycle for synchronous memory
                        ;
                    st: begin
                        // ... your code goes here
						Sel=rX;
						DOUT_in= 1'b1;
						W_D=1'b1;
                    end
                    default: ; 
                endcase
            T5: // define T3
                case (III)
                    add, sub, and_: begin
                        // ... your code goes here
						Sel=SEL_G;
						rX_in=1'b1;
						Done=1'b1;
                    end
					mvt: begin
						if(!Imm) begin 
							Sel = SEL_G;
							F_in=1'b0;
							case (rX)
								b: begin
									pc_in=1'b1;
								end
								beq: begin
									if(z) pc_in=1'b1;
									else pc_in=1'b0;
								end
								bne: begin
									if(!z) pc_in=1'b1;
									else pc_in=1'b0;
								end
								bcc: begin 
									if(!c) pc_in=1'b1;
									else pc_in=1'b0;
								end
								bcs: begin
									if(c) pc_in=1'b1;
									else pc_in=1'b0;
								end
								bpl: begin
									if(!n) pc_in=1'b1;
									else pc_in=1'b0;
								end
								bmi: begin
									if(n) pc_in=1'b1;
									else pc_in=1'b0;
								end
								default: ;
							endcase
						end
						else;
					end
                    ld: begin
                        // ... your code goes here
						Sel=SEL_DIN;
						rX_in=1'b1;
						Done=1'b1;
                    end
                    st: // wait cycle for synhronous memory
                        // ... your code goes here
						Done=1'b1;
                    default: ;
                endcase
            default: ;
        endcase
    end   
   
    // Control FSM flip-flops
    always @(posedge Clock)
        if (!Resetn)
            Tstep_Q <= T0;
        else
            Tstep_Q <= Tstep_D;   
   
    regn reg_0 (BusWires, Resetn, R_in[0], Clock, r0);
    regn reg_1 (BusWires, Resetn, R_in[1], Clock, r1);
    regn reg_2 (BusWires, Resetn, R_in[2], Clock, r2);
    regn reg_3 (BusWires, Resetn, R_in[3], Clock, r3);
    regn reg_4 (BusWires, Resetn, R_in[4], Clock, r4);
    regn reg_5 (BusWires, Resetn, R_in[5], Clock, r5);
    regn reg_6 (BusWires, Resetn, R_in[6], Clock, r6);
	
	//flag hold register
	regn #(.n(3)) reg_F ({cout, Sum[15], &(~Sum)}, Resetn, F_in, Clock, flag);
	 

    // r7 is program counter
    // module pc_count(R, Resetn, Clock, E, L, Q);
    pc_count reg_pc (BusWires, Resetn, Clock, pc_incr, pc_in, pc);

    regn reg_A (BusWires, Resetn, A_in, Clock, A);
    regn reg_DOUT (BusWires, Resetn, DOUT_in, Clock, DOUT);
    regn reg_ADDR (BusWires, Resetn, ADDR_in, Clock, ADDR);
    regn reg_IR (DIN, Resetn, IR_in, Clock, IR);

    flipflop reg_W (W_D, Resetn, Clock, W);
    
    // alu
    always @(*)
        if (!ALU_and)
            if (!AddSub)
               
				{cout, Sum}= A + BusWires;
            else
                Sum = A + ~BusWires + 16'b1;
		  else
            Sum = A & BusWires;
    regn reg_G (Sum, Resetn, G_in, Clock, G);

    // define the internal processor bus
    always @(*)
        case (Sel)
            SEL_R0: BusWires = r0;
            SEL_R1: BusWires = r1;
            SEL_R2: BusWires = r2;
            SEL_R3: BusWires = r3;
            SEL_R4: BusWires = r4;
            SEL_R5: BusWires = r5;
            SEL_R6: BusWires = r6;
            SEL_PC: BusWires = pc;
            SEL_G: BusWires = G;
            SEL_D: BusWires = {{7{IR[8]}}, IR[8:0]}; // sign extended
            SEL_D8: BusWires = {IR[7:0], 8'b0};
            default: BusWires = DIN;
        endcase
endmodule

module pc_count(R, Resetn, Clock, E, L, Q);
    input [15:0] R;
    input Resetn, Clock, E, L;
    output [15:0] Q;
    reg [15:0] Q;
   
    always @(posedge Clock)
        if (!Resetn)
            Q <= 16'b0;
        else if (L)
            Q <= R;
        else if (E)
            Q <= Q + 1'b1;
endmodule

module dec3to8(E, W, Y);
    input E; // enable
    input [2:0] W;
    output [0:7] Y;
    reg [0:7] Y;
   
    always @(*)
        if (E == 0)
            Y = 8'b00000000;
        else
            case (W)
                3'b000: Y = 8'b10000000;
                3'b001: Y = 8'b01000000;
                3'b010: Y = 8'b00100000;
                3'b011: Y = 8'b00010000;
                3'b100: Y = 8'b00001000;
                3'b101: Y = 8'b00000100;
                3'b110: Y = 8'b00000010;
                3'b111: Y = 8'b00000001;
            endcase
endmodule

module regn(R, Resetn, E, Clock, Q);
    parameter n = 16;
    input [n-1:0] R;
    input Resetn, E, Clock;
    output [n-1:0] Q;
    reg [n-1:0] Q;

    always @(posedge Clock)
        if (!Resetn)
            Q <= 0;
        else if (E)
            Q <= R;
endmodule
