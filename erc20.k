requires "domains.md"
module ERC20
    imports BOOL
    imports MAP
    imports LIST
    imports INT

    configuration <k> $PGM:Steps </k>
    <balances> .Map </balances>
    <allowances> .Map </allowances>
    <totalsupply> 0:Int </totalsupply>
    <output> .List </output>
    <approvals>
        <approval multiplicity="*" type="Map">
            <owner>0</owner>
            <spenders>.Map</spenders>
        </approval>
     </approvals>


    // Cons list constructor. Second param indicates
    // the separator of each item in the cons list
    syntax Steps ::= List{Step, ""}
    
    rule <k> (STEP STEPS:Steps) => STEP ~> STEPS ... </k>

    rule <k> .Steps => . ... </k>

    syntax Step ::= "return" Int 
                    | TotalSupply() 
                    | BalanceOf(Int) 
                    | Mint(Int, Int)
                    | Burn(Int, Int)
                    | Transfer(Int, Int, Int)
                    | Approve(Int, Int, Int)
                    | Allowance(Int, Int)

    rule <k> BalanceOf(_ADDR) => return 0 ... </k> [owise]

    // rule <k> BalanceOf(ADDR) ~> REST => return 0 ~> REST </k> [owise]

    // STEP ~> STEPS handles STEP first because our rules focus
    // on the first item in the k cell indicated by the fact that the 
    // ... operator is AFTER the rewrite rule
    rule <k> BalanceOf(ADDR) => return BALANCE ... </k>
         <balances> ... ADDR |-> BALANCE ... </balances>

    rule <k> TotalSupply() => return TOTALSUPPLY ... </k>
        <totalsupply> TOTALSUPPLY </totalsupply>

    rule <k> return V => . ... </k>
         <output> ... (.List => ListItem(V)) </output>

    rule <k> Mint(ADDR, AMT) => . ... </k> requires AMT <Int 0
        

    rule <k> Mint(ADDR, AMT) => . ... </k>
        <balances> ... ADDR |-> (BALANCE => BALANCE +Int AMT) ... </balances>
        <totalsupply> TOTALSUPPLY => TOTALSUPPLY +Int AMT </totalsupply>
        requires AMT >=Int 0

    /**
        this would allow us to not mention total supply cell in both rules
        Since there is no rewrite operator, the Mint(ADDR,AMT) will be in the front of the k cell
        after this rule completes
        rule <k> Mint(ADDR, AMT) ... </k>
        <balances> BALANCES => BALANCES[ADDR <- 0] </balances> [owise]
    
     */
    rule <k> Mint(ADDR, AMT) => . ... </k>
        <balances> BALANCES => BALANCES[ADDR <- AMT] </balances> 
        <totalsupply> TOTALSUPPLY => TOTALSUPPLY +Int AMT </totalsupply> [owise]

    rule <k> Burn(ADDR, AMT) => . ... </k>
         <balances> ... ADDR |-> (BALANCE => BALANCE -Int AMT) ... </balances>
         <totalsupply> TOTALSUPPLY => TOTALSUPPLY -Int AMT </totalsupply>
         requires AMT <=Int BALANCE

    
    rule <k> Burn(ADDR, AMT) => . ... </k> requires AMT <Int 0

    rule <k>Burn(ADDR, AMT) ... </k>
         <balances> BALANCES => BALANCES[ADDR <- 0]</balances> [owise]


    // Add this rule so that if the DST does not yet exist,
    // it will add it to balances map prior to running any other rules
     rule <k>Transfer(SRC, DST, AMT) ... </k>
         <balances> BALANCES => BALANCES[DST <- 0]</balances> [owise]
         
    // Valid transfer operation
    rule <k> Transfer(SRC, DST, AMT) => . ... </k>
         <balances>
            ... 
            SRC |-> (BALANCESRC => BALANCESRC -Int AMT)
            DST |-> (BALANCEDST => BALANCEDST +Int AMT)
            ...
         </balances> requires BALANCESRC >=Int AMT

    // Handle when transfer amt < sender balance
    rule <k> Transfer(SRC, DST, AMT) => . ... </k>
        <balances> ... SRC |-> BALANCESRC ... </balances>
        requires BALANCESRC <Int AMT

    rule <k> Approve(OWNER, SPENDER, AMT) => . ...</k>
            <approval> 
                ...
                    <owner> OWNER </owner>
                    <spenders> SPENDERS => SPENDERS[SPENDER <- AMT] </spenders>
                ...
            </approval>

    // If OWNER is not in approvals cell map, insert one
    // with empty approvals before moving on
    rule <k> Approve(OWNER, SPENDER, AMT) ... </k>
         <approvals> 
         ... 
         (
            .Bag => 
            <approval>
                <owner> OWNER </owner>
                <spenders> .Map </spenders> 
            </approval>
         ) 
         ... 
         </approvals> [owise]

    rule <k>Allowance(OWNER, SPENDER) => return AMT ... </k>
         <approvals>
                <approval>
                    <owner> OWNER </owner>
                    <spenders> ... (SPENDER |-> AMT) ... </spenders>
                </approval>
         </approvals>
        
    
     
endmodule