 
module multiplier (a, b, prod, qnan, infinity, zero, normal, clk);
input [15:0] a,b;
input clk;
output reg [15:0] prod;
output reg qnan, infinity, zero, normal;

reg [15:0] x,y;
wire [15:0] p;
wire qn, inf, zer, norm;

mul DUU (.a(x), .b(y), .p(p), .qnan(qn), .infinity(inf), .zero(zer), .normal(norm));

always @(posedge clk) begin
	x <= a;
	y <= b;
 
 	qnan <= qn;
	infinity <= inf;
	zero <= zer;
	normal <= norm;
	prod <= p;
end

endmodule



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module mul(a, b, p, qnan, infinity, zero, normal);
  input [15:0] a, b;
  output [15:0] p;
  output infinity, zero, normal, qnan;
  reg infinity, zero, normal, qnan;
    
  wire aInfinity, aZero, aNormal;
  wire bInfinity, bZero, bNormal;

  wire signed [6:0] aExp, bExp;
  reg signed [6:0] pExp, t1Exp, t2Exp;
  wire [10:0] aSig, bSig;
  reg [10:0] pSig, tSig;

  reg [15:0] pTmp;
  
  wire [21:0] rawSignificand;
  
  reg pSign;
  
  class aClass(.f(a), .fExp(aExp), .fSig(aSig), .isInfinity(aInfinity), .isZero(aZero), .isNormal(aNormal));
  class bClass(.f(b), .fExp(bExp), .fSig(bSig), .isInfinity(bInfinity), .isZero(bZero), .isNormal(bNormal));
  
  //assign rawSignificand = aSig * bSig;
  WTM multiplier (.result(rawSignificand), .a(aSig), .b(bSig));

  always @(*)
  begin
    pSign = a[15] ^ b[15];
    pTmp = {pSign, {5{1'b1}}, 1'b0, {9{1'b1}}};  // Initialize p to be an sNaN.
    {infinity, zero, qnan, normal} = 6'b0000;
    
    if (((aInfinity & bZero) == 1'b1) || ((bInfinity & aZero) == 1'b1))
      begin
			pTmp = {pSign, {5{1'b1}}, 1'b1, 9'h2A}; // qNaN
         qnan = 1;
      end
	 else if (((aInfinity & ~bZero) == 1'b1) || ((bInfinity & ~aZero) == 1'b1))
		begin
			pTmp = {pSign, {5{1'b1}}, {10{1'b0}}};
         infinity = 1;
		end
    else if ((aZero | bZero) == 1'b1)
      begin
        pTmp = {pSign, {15{1'b0}}};
        zero = 1;
      end
    else    
      begin // Handling Normal mul
        t1Exp = aExp + bExp;

        if (rawSignificand[21] == 1'b1) //Normalization
          begin
            tSig = rawSignificand[21:11];
            t2Exp = t1Exp + 1;
          end
        else
          begin
            tSig = rawSignificand[20:10];
            t2Exp = t1Exp;
          end

		  if (t2Exp > 15) // Infinity
          begin
            pTmp = {pSign, {5{1'b1}}, {10{1'b0}}};
            infinity = 1;
          end
        else // Normal
          begin
            pExp = t2Exp + 15;
            pSig = tSig;
            pTmp = {pSign, pExp[4:0], pSig[9:0]};
            normal = 1;
          end
      end
  end
  
  assign p = pTmp;
    
endmodule



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module fa (
    input x,y,cin,
    output sum,cout
);

assign sum = x ^ y ^ cin;
assign cout = (x&y) | (y&cin) | (x&cin);

endmodule



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


module ha (
    input x,y,
    output sum,cout
);

assign sum = x ^ y;
assign cout = (x&y);

endmodule

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module WTM (result, a, b);

input [10:0] a, b;
output [21:0] result;

reg         a0b0,a1b0,a2b0,a3b0,a4b0,a5b0,a6b0,a7b0,a8b0,a9b0,a10b0,
            a0b1,a1b1,a2b1,a3b1,a4b1,a5b1,a6b1,a7b1,a8b1,a9b1,a10b1,
            a0b2,a1b2,a2b2,a3b2,a4b2,a5b2,a6b2,a7b2,a8b2,a9b2,a10b2,
            a0b3,a1b3,a2b3,a3b3,a4b3,a5b3,a6b3,a7b3,a8b3,a9b3,a10b3,
            a0b4,a1b4,a2b4,a3b4,a4b4,a5b4,a6b4,a7b4,a8b4,a9b4,a10b4,
            a0b5,a1b5,a2b5,a3b5,a4b5,a5b5,a6b5,a7b5,a8b5,a9b5,a10b5,
            a0b6,a1b6,a2b6,a3b6,a4b6,a5b6,a6b6,a7b6,a8b6,a9b6,a10b6,
            a0b7,a1b7,a2b7,a3b7,a4b7,a5b7,a6b7,a7b7,a8b7,a9b7,a10b7,
            a0b8,a1b8,a2b8,a3b8,a4b8,a5b8,a6b8,a7b8,a8b8,a9b8,a10b8,
            a0b9,a1b9,a2b9,a3b9,a4b9,a5b9,a6b9,a7b9,a8b9,a9b9,a10b9,
            a0b10,a1b10,a2b10,a3b10,a4b10,a5b10,a6b10,a7b10, a8b10,a9b10,a10b10;


//cout and sum left to define...wait
wire [34:1] s1, c1; //stage 1 sum and cout
wire [23:1] s2, c2; //stage 2 sum and cout
wire [15:1] s3, c3;  //stage 3 sum and cout
wire [14:1] s4, c4;  //stage 4 sum and cout
wire [11:1] s5, c5;  //stage 5 sum and cout
//wire [14:0] x,y; //final add rows
wire [15:0] add;

//Partial Products Generation
always @(*) begin
    a0b0 = a[0] & b[0];
    a1b0 = a[1] & b[0];
    a2b0 = a[2] & b[0];
    a3b0 = a[3] & b[0];
    a4b0 = a[4] & b[0];
    a5b0 = a[5] & b[0];
    a6b0 = a[6] & b[0];
    a7b0 = a[7] & b[0];
    a8b0 = a[8] & b[0];
    a9b0 = a[9] & b[0];
    a10b0 = a[10] & b[0];

    a0b1 = a[0] & b[1];
    a1b1 = a[1] & b[1];
    a2b1 = a[2] & b[1];
    a3b1 = a[3] & b[1];
    a4b1 = a[4] & b[1];
    a5b1 = a[5] & b[1];
    a6b1 = a[6] & b[1];
    a7b1 = a[7] & b[1];
    a8b1 = a[8] & b[1];
    a9b1 = a[9] & b[1];
    a10b1 = a[10] & b[1];


    a0b2 = a[0] & b[2];
    a1b2 = a[1] & b[2];
    a2b2 = a[2] & b[2];
    a3b2 = a[3] & b[2];
    a4b2 = a[4] & b[2];
    a5b2 = a[5] & b[2];
    a6b2 = a[6] & b[2];
    a7b2 = a[7] & b[2];
    a8b2 = a[8] & b[2];
    a9b2 = a[9] & b[2];
    a10b2 = a[10] & b[2];

    a0b3 = a[0] & b[3];
    a1b3 = a[1] & b[3];
    a2b3 = a[2] & b[3];
    a3b3 = a[3] & b[3];
    a4b3 = a[4] & b[3];
    a5b3 = a[5] & b[3];
    a6b3 = a[6] & b[3];
    a7b3 = a[7] & b[3];
    a8b3 = a[8] & b[3];
    a9b3 = a[9] & b[3];
    a10b3 = a[10] & b[3];

    a0b4 = a[0] & b[4];
    a1b4 = a[1] & b[4];
    a2b4 = a[2] & b[4];
    a3b4 = a[3] & b[4];
    a4b4 = a[4] & b[4];
    a5b4 = a[5] & b[4];
    a6b4 = a[6] & b[4];
    a7b4 = a[7] & b[4];
    a8b4 = a[8] & b[4];
    a9b4 = a[9] & b[4];
    a10b4 = a[10] & b[4];

    a0b5 = a[0] & b[5];
    a1b5 = a[1] & b[5];
    a2b5 = a[2] & b[5];
    a3b5 = a[3] & b[5];
    a4b5 = a[4] & b[5];
    a5b5 = a[5] & b[5];
    a6b5 = a[6] & b[5];
    a7b5 = a[7] & b[5];
    a8b5 = a[8] & b[5];
    a9b5 = a[9] & b[5];
    a10b5 = a[10] & b[5];

    a0b6 = a[0] & b[6];
    a1b6 = a[1] & b[6];
    a2b6 = a[2] & b[6];
    a3b6 = a[3] & b[6];
    a4b6 = a[4] & b[6];
    a5b6 = a[5] & b[6];
    a6b6 = a[6] & b[6];
    a7b6 = a[7] & b[6];
    a8b6 = a[8] & b[6];
    a9b6 = a[9] & b[6];
    a10b6 = a[10] & b[6];

    a0b7 = a[0] & b[7];
    a1b7 = a[1] & b[7];
    a2b7 = a[2] & b[7];
    a3b7 = a[3] & b[7];
    a4b7 = a[4] & b[7];
    a5b7 = a[5] & b[7];
    a6b7 = a[6] & b[7];
    a7b7 = a[7] & b[7];
    a8b7 = a[8] & b[7];
    a9b7 = a[9] & b[7];
    a10b7 = a[10] & b[7];

    a0b8 = a[0] & b[8];
    a1b8 = a[1] & b[8];
    a2b8 = a[2] & b[8];
    a3b8 = a[3] & b[8];
    a4b8 = a[4] & b[8];
    a5b8 = a[5] & b[8];
    a6b8 = a[6] & b[8];
    a7b8 = a[7] & b[8];
    a8b8 = a[8] & b[8];
    a9b8 = a[9] & b[8];
    a10b8 = a[10] & b[8];

    a0b9 = a[0] & b[9];
    a1b9 = a[1] & b[9];
    a2b9 = a[2] & b[9];
    a3b9 = a[3] & b[9];
    a4b9 = a[4] & b[9];
    a5b9 = a[5] & b[9];
    a6b9 = a[6] & b[9];
    a7b9 = a[7] & b[9];
    a8b9 = a[8] & b[9];
    a9b9 = a[9] & b[9];
    a10b9 = a[10] & b[9];

    a0b10 = a[0] & b[10];
    a1b10 = a[1] & b[10];
    a2b10 = a[2] & b[10];
    a3b10 = a[3] & b[10];
    a4b10 = a[4] & b[10];
    a5b10 = a[5] & b[10];
    a6b10 = a[6] & b[10];
    a7b10 = a[7] & b[10];
    a8b10 = a[8] & b[10];
    a9b10 = a[9] & b[10];
    a10b10 = a[10] & b[10];
end

//STAGE 1 (xx + stage no + xx's no)
ha ha11 (.sum(s1[1]), .cout(c1[1]), .x(a1b0), .y(a0b1));
fa fa11 (.sum(s1[2]), .cout(c1[2]), .x(a2b0), .y(a1b1), .cin(a0b2));
fa fa12 (.sum(s1[3]), .cout(c1[3]), .x(a3b0), .y(a2b1), .cin(a1b2));
fa fa13 (.sum(s1[4]), .cout(c1[4]), .x(a4b0), .y(a3b1), .cin(a2b2));
fa fa14 (.sum(s1[5]), .cout(c1[5]), .x(a5b0), .y(a4b1), .cin(a3b2));
fa fa15 (.sum(s1[6]), .cout(c1[6]), .x(a2b3), .y(a1b4), .cin(a0b5));
fa fa16 (.sum(s1[7]), .cout(c1[7]), .x(a6b0), .y(a5b1), .cin(a4b2));
fa fa17 (.sum(s1[8]), .cout(c1[8]), .x(a3b3), .y(a2b4), .cin(a1b5));
fa fa18 (.sum(s1[9]), .cout(c1[9]), .x(a7b0), .y(a6b1), .cin(a5b2)); 
fa fa19 (.sum(s1[10]), .cout(c1[10]), .x(a4b3), .y(a3b4), .cin(a2b5)); 
fa fa110 (.sum(s1[11]), .cout(c1[11]), .x(a8b0), .y(a7b1), .cin(a6b2)); 

fa fa111 (.sum(s1[12]), .cout(c1[12]), .x(a5b3), .y(a4b4), .cin(a3b5)); 
fa fa112 (.sum(s1[13]), .cout(c1[13]), .x(a2b6), .y(a1b7), .cin(a0b8)); 
fa fa113 (.sum(s1[14]), .cout(c1[14]), .x(a9b0), .y(a8b1), .cin(a7b2));
fa fa114 (.sum(s1[15]), .cout(c1[15]), .x(a6b3), .y(a5b4), .cin(a4b5));
fa fa115 (.sum(s1[16]), .cout(c1[16]), .x(a3b6), .y(a2b7), .cin(a1b8));
fa fa116 (.sum(s1[17]), .cout(c1[17]), .x(a10b0), .y(a9b1), .cin(a8b2));
fa fa117 (.sum(s1[18]), .cout(c1[18]), .x(a7b3), .y(a6b4), .cin(a5b5));
fa fa118 (.sum(s1[19]), .cout(c1[19]), .x(a4b6), .y(a3b7), .cin(a2b8));
fa fa119 (.sum(s1[20]), .cout(c1[20]), .x(a10b1), .y(a9b2), .cin(a8b3));
fa fa120 (.sum(s1[21]), .cout(c1[21]), .x(a7b4), .y(a6b5), .cin(a5b6));

fa fa121 (.sum(s1[22]), .cout(c1[22]), .x(a4b7), .y(a3b8), .cin(a2b9));
fa fa122 (.sum(s1[23]), .cout(c1[23]), .x(a10b2), .y(a9b3), .cin(a8b4));
fa fa123 (.sum(s1[24]), .cout(c1[24]), .x(a7b5), .y(a6b6), .cin(a5b7));
fa fa124 (.sum(s1[25]), .cout(c1[25]), .x(a4b8), .y(a3b9), .cin(a2b10));
fa fa125 (.sum(s1[26]), .cout(c1[26]), .x(a10b3), .y(a9b4), .cin(a8b5));
fa fa126 (.sum(s1[27]), .cout(c1[27]), .x(a7b6), .y(a6b7), .cin(a5b8));
fa fa127 (.sum(s1[28]), .cout(c1[28]), .x(a10b4), .y(a9b5), .cin(a8b6));
fa fa128 (.sum(s1[29]), .cout(c1[29]), .x(a7b7), .y(a6b8), .cin(a5b9));
fa fa129 (.sum(s1[30]), .cout(c1[30]), .x(a10b5), .y(a9b6), .cin(a8b7));
fa fa130 (.sum(s1[31]), .cout(c1[31]), .x(a7b8), .y(a6b9), .cin(a5b10));
fa fa131 (.sum(s1[32]), .cout(c1[32]), .x(a10b6), .y(a9b7), .cin(a8b8));
fa fa132 (.sum(s1[33]), .cout(c1[33]), .x(a10b7), .y(a9b8), .cin(a8b9));
fa fa133 (.sum(s1[34]), .cout(c1[34]), .x(a10b8), .y(a9b9), .cin(a8b10));


//STAGE 2
ha ha21 (.sum(s2[1]), .cout(c2[1]), .x(c1[1]), .y(s1[2]));
fa fa21 (.sum(s2[2]), .cout(c2[2]), .x(c1[2]), .y(s1[3]), .cin(a0b3));
fa fa22 (.sum(s2[3]), .cout(c2[3]), .x(c1[3]), .y(s1[4]), .cin(a1b3));
fa fa23 (.sum(s2[4]), .cout(c2[4]), .x(c1[4]), .y(s1[5]), .cin(s1[6]));
fa fa24 (.sum(s2[5]), .cout(c2[5]), .x(c1[5]), .y(c1[6]), .cin(s1[7]));
fa fa25 (.sum(s2[6]), .cout(c2[6]), .x(c1[7]), .y(c1[8]), .cin(s1[9]));
fa fa26 (.sum(s2[7]), .cout(c2[7]), .x(s1[10]), .y(a1b6), .cin(a0b7));
fa fa27 (.sum(s2[8]), .cout(c2[8]), .x(c1[9]), .y(c1[10]), .cin(s1[11]));
fa fa28 (.sum(s2[9]), .cout(c2[9]), .x(c1[11]), .y(c1[12]), .cin(c1[13])); 
fa fa29 (.sum(s2[10]), .cout(c2[10]), .x(s1[14]), .y(s1[15]), .cin(s1[16]));
fa fa210 (.sum(s2[11]), .cout(c2[11]), .x(c1[14]), .y(c1[15]), .cin(c1[16]));

fa fa211 (.sum(s2[12]), .cout(c2[12]), .x(s1[17]), .y(s1[18]), .cin(s1[19]));
fa fa212 (.sum(s2[13]), .cout(c2[13]), .x(c1[17]), .y(c1[18]), .cin(c1[19]));
fa fa213 (.sum(s2[14]), .cout(c2[14]), .x(s1[20]), .y(s1[21]), .cin(s1[22]));
fa fa214 (.sum(s2[15]), .cout(c2[15]), .x(c1[20]), .y(c1[21]), .cin(c1[22]));
fa fa215 (.sum(s2[16]), .cout(c2[16]), .x(s1[23]), .y(s1[24]), .cin(s1[25]));
fa fa216 (.sum(s2[17]), .cout(c2[17]), .x(c1[23]), .y(c1[24]), .cin(c1[25]));
fa fa217 (.sum(s2[18]), .cout(c2[18]), .x(s1[26]), .y(s1[27]), .cin(a4b9));
fa fa218 (.sum(s2[19]), .cout(c2[19]), .x(c1[26]), .y(c1[27]), .cin(s1[28]));
fa fa219 (.sum(s2[20]), .cout(c2[20]), .x(c1[28]), .y(c1[29]), .cin(s1[30]));
fa fa220 (.sum(s2[21]), .cout(c2[21]), .x(c1[30]), .y(c1[31]), .cin(s1[32]));

fa fa221 (.sum(s2[22]), .cout(c2[22]), .x(c1[32]), .y(s1[33]), .cin(a7b10));
fa fa222 (.sum(s2[23]), .cout(c2[23]), .x(c1[34]), .y(a10b9), .cin(a9b10));


//STAGE 3
ha ha31 (.sum(s3[1]), .cout(c3[1]), .x(c2[1]), .y(s2[2]));
fa fa31 (.sum(s3[2]), .cout(c3[2]), .x(c2[2]), .y(s2[3]), .cin(a0b4));
fa fa32 (.sum(s3[3]), .cout(c3[3]), .x(c2[4]), .y(s2[5]), .cin(s1[8]));
fa fa33 (.sum(s3[4]), .cout(c3[4]), .x(c2[5]), .y(s2[6]), .cin(s2[7]));
fa fa34 (.sum(s3[5]), .cout(c3[5]), .x(c2[6]), .y(c2[7]), .cin(s2[8]));
fa fa35 (.sum(s3[6]), .cout(c3[6]), .x(c2[8]), .y(s2[9]), .cin(s2[10]));
fa fa36 (.sum(s3[7]), .cout(c3[7]), .x(c2[9]), .y(c2[10]), .cin(s2[11]));
fa fa37 (.sum(s3[8]), .cout(c3[8]), .x(s2[12]), .y(a1b9), .cin(a0b10));
fa fa38 (.sum(s3[9]), .cout(c3[9]), .x(c2[11]), .y(c2[12]), .cin(s2[13]));
fa fa39 (.sum(s3[10]), .cout(c3[10]), .x(c2[13]), .y(c2[14]), .cin(s2[15]));
fa fa310 (.sum(s3[11]), .cout(c3[11]), .x(c2[15]), .y(c2[16]), .cin(s2[17]));

fa fa311 (.sum(s3[12]), .cout(c3[12]), .x(c2[17]), .y(c2[18]), .cin(s2[19]));
fa fa312 (.sum(s3[13]), .cout(c3[13]), .x(c2[19]), .y(s2[20]), .cin(s1[31]));
fa fa313 (.sum(s3[14]), .cout(c3[14]), .x(c2[20]), .y(s2[21]), .cin(a7b9));
fa fa314 (.sum(s3[15]), .cout(c3[15]), .x(c2[22]), .y(c1[33]), .cin(s1[34]));


//STAGE 4
ha ha41 (.sum(s4[1]), .cout(c4[1]), .x(c3[1]), .y(s3[2]));
fa fa41 (.sum(s4[2]), .cout(c4[2]), .x(c3[2]), .y(c2[3]), .cin(s2[4]));
ha ha42 (.sum(s4[3]), .cout(c4[3]), .x(s3[3]), .y(a0b6));
ha ha43 (.sum(s4[4]), .cout(c4[4]), .x(c3[3]), .y(s3[4]));
fa fa42 (.sum(s4[5]), .cout(c4[5]), .x(c3[4]), .y(s3[5]), .cin(s1[12]));
fa fa43 (.sum(s4[6]), .cout(c4[6]), .x(c3[5]), .y(s3[6]), .cin(a0b9));
fa fa44 (.sum(s4[7]), .cout(c4[7]), .x(c3[6]), .y(s3[7]), .cin(s3[8]));
fa fa45 (.sum(s4[8]), .cout(c4[8]), .x(c3[7]), .y(c3[8]), .cin(s2[14]));
ha ha44 (.sum(s4[9]), .cout(c4[9]), .x(a1b10), .y(s3[9]));
fa fa46 (.sum(s4[10]), .cout(c4[10]), .x(c3[9]), .y(s2[16]), .cin(s3[10]));
fa fa47 (.sum(s4[11]), .cout(c4[11]), .x(c3[10]), .y(s2[18]), .cin(a3b10));
fa fa48 (.sum(s4[12]), .cout(c4[12]), .x(c3[11]), .y(s1[29]), .cin(a4b10));
fa fa49 (.sum(s4[13]), .cout(c4[13]), .x(c3[13]), .y(a6b10), .cin(s3[14]));
fa fa410 (.sum(s4[14]), .cout(c4[14]), .x(c3[14]), .y(c2[21]), .cin(s2[22]));


//STAGE 5
ha ha51 (.sum(s5[1]), .cout(c5[1]), .x(c4[1]), .y(s4[2]));
ha ha52 (.sum(s5[2]), .cout(c5[2]), .x(c4[2]), .y(s4[3]));
ha ha53 (.sum(s5[3]), .cout(c5[3]), .x(c4[3]), .y(s4[4]));
fa fa51 (.sum(s5[4]), .cout(c5[4]), .x(c4[4]), .y(s1[13]), .cin(s4[5]));
ha ha54 (.sum(s5[5]), .cout(c5[5]), .x(c4[5]), .y(s4[6]));
ha ha55 (.sum(s5[6]), .cout(c5[6]), .x(c4[6]), .y(s4[7]));
fa fa52 (.sum(s5[7]), .cout(c5[7]), .x(c4[7]), .y(s4[8]), .cin(s4[9]));
fa fa53 (.sum(s5[8]), .cout(c5[8]), .x(c4[8]), .y(c4[9]), .cin(s4[10]));
fa fa54 (.sum(s5[9]), .cout(c5[9]), .x(c4[10]), .y(s3[11]), .cin(s4[11]));
fa fa55 (.sum(s5[10]), .cout(c5[10]), .x(c4[11]), .y(s3[12]), .cin(s4[12]));
fa fa56 (.sum(s5[11]), .cout(c5[11]), .x(c4[12]), .y(c3[12]), .cin(s3[13]));


//Add - change this!
//assign result = {a10b10,c3[15],c4[14],c4[13],c5[11],c5[10],c5[9],c5[8],c5[7],c5[6],c5[5],c5[4],c5[3],c5[2],c5[1],s5[1],s4[1],s3[1],s2[1],s1[1],a0b0} + {c2[23],s2[23],s3[15],s4[14],s4[13],s5[11],s5[10],s5[9],s5[8],s5[7],s5[6],s5[5],s5[4],s5[3],s5[2],{6{1'b0}}};

CLA adder (.result(add), .a({a10b10,c3[15],c4[14],c4[13],c5[11],c5[10],c5[9],c5[8],c5[7],c5[6],c5[5],c5[4],c5[3],c5[2],c5[1]}), .b({c2[23],s2[23],s3[15],s4[14],s4[13],s5[11],s5[10],s5[9],s5[8],s5[7],s5[6],s5[5],s5[4],s5[3],s5[2]}), .carry_in(1'b0));

assign result = {add, {s5[1],s4[1],s3[1],s2[1],s1[1],a0b0}};
endmodule

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


module CLA (
    input [14:0] a,        // 15-bit input A
    input [14:0] b,        // 15-bit input B
    input carry_in,        // Carry input
    output [15:0] result     // 15-bit sum output
    //output carry_out       // Carry output
);
    wire [14:0] p;         // Propagate
    wire [14:0] g;         // Generate
    wire [15:0] c;         // Carry bits

    // Generate and Propagate signals
    assign p = a ^ b;      // Propagate: P[i] = A[i] XOR B[i]
    assign g = a & b;      // Generate: G[i] = A[i] AND B[i]

    // Carry generation
    assign c[0] = carry_in; // First carry is the carry-in
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & c[1]);
    assign c[3] = g[2] | (p[2] & c[2]);
    assign c[4] = g[3] | (p[3] & c[3]);
    assign c[5] = g[4] | (p[4] & c[4]);
    assign c[6] = g[5] | (p[5] & c[5]);
    assign c[7] = g[6] | (p[6] & c[6]);
    assign c[8] = g[7] | (p[7] & c[7]);
    assign c[9] = g[8] | (p[8] & c[8]);
    assign c[10] = g[9] | (p[9] & c[9]);
    assign c[11] = g[10] | (p[10] & c[10]);
    assign c[12] = g[11] | (p[11] & c[11]);
    assign c[13] = g[12] | (p[12] & c[12]);
    assign c[14] = g[13] | (p[13] & c[13]);
    assign c[15] = g[14] | (p[14] & c[14]); // Final carry

    // Sum calculation
    //assign sum = p ^ c[14:0]; // Sum: S[i] = P[i] XOR C[i]

    // Final carry output
    //assign carry_out = c[15]; // Carry output
	 
	 assign result = {c[15], p ^ c[14:0]};

endmodule


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


module class(f, fExp, fSig, isInfinity, isZero, isNormal);
    input [15:0] f;
    output signed [6:0] fExp;
    reg signed [6:0] fExp;
    output [10:0] fSig;
    reg [10:0] fSig;
    output  isInfinity, isZero, isNormal;
    
    wire expOnes, expZeroes, sigZeroes;
    
    assign expOnes   =  &f[14:10];
    assign expZeroes = ~|f[14:10];
    assign sigZeroes = ~|f[9:0];
    
    
    assign isInfinity  =  expOnes   &  sigZeroes;
    assign isZero      =  expZeroes &  sigZeroes;
    assign isNormal    = ~expOnes   & ~expZeroes;
    
    
    always @(*)
      begin
        fExp = f[14:10];
        fSig = f[9:0];

        if (isNormal) {fExp, fSig} = {f[14:10] - 15, 1'b1, f[9:0]};
    end
endmodule


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////






