%{
/* Flex tokeniser and sentence boundary finder for Malay text in plain
   ASCII or Latin-1 (8-bit) format.
 
   Author: Tim Baldwin, University of Melbourne

   Adapted from code by John Carroll, in turn adapted from code by Guido
   Minnen, Erik Hektoen, and Greg Grefenstette.

   All control chars, as well as space and Latin-1 non-breakable space, are
   regarded as whitespace.  This file consists only ASCII characters.  

*/

#define YY_INPUT(buf,result,max_size) \
              { \
              int c = getchar(); \
              result = (c == EOF) ? YY_NULL : (buf[0] = c, 1); \
              }
#define ECHO (void) fwrite( yytext, yyleng, 1, yyout ); fflush(yyout)

int sent = 0;
int nl = 0;

%}

  /* Character classes */

upper    [A-Z\xC0-\xD6\xD8-\xDE]
lower    [a-z\xDF-\xF6\xF8-\xFF]
lcons    [bcdfghj-np-tvxz]
letter   [A-Za-z\xC0-\xD6\xD8-\xDE\xDF-\xF6\xF8-\xFF]
   /* {lower}|{upper} */
digit    [0-9]
symbol   [!-/:-@[-`{-~\xA1-\xBF\xD7\xF7]
ns       {letter}|{digit}|{symbol}
sp       " "|\t
nl       \n|\r
spnl     {sp}|{nl}
trail      [!?;:,|/)\]'".]|''
trail_nop  [!?;:,|/)\]'"]|''
trail_mid  [!?;:,|/]
trail_end  [)\]'"]|''
end      {trail}*{spnl}
end_nop  {trail_nop}*{spnl}

  /* Abbrevations */ 

  /* All abbreviations end with a period '.' */

abbrev  "Abd."|"Ab."|"Mohd."|"Md."|"Muhd."|"Bhd."|"Drs."|"Dr."|"Dt."|"Inc."|"Sdn."|"St."|"Jln."|"Kapt."|"kg."|"kump"|"LL.B."|"LL.M"|"Lt."|"per."|"Pn."|"Pt."|"Rp."|"Tmn."|"Tn."|"Tkt."|"Tj."|"Y.bhg"|"ABD."|"AB."|"MOHD."|"MD."|"MUHD."|"BHD."|"DRS."|"DR."|"DT."|"INC."|"SDN."|"ST."|"JLN."|"KAPT."|"KG."|"KUMP"|"LL.B."|"LL.M"|"LT."|"PER."|"PN."|"PT."|"RP."|"TMN."|"TN."|"TKT."|"TJ."|"Y.BHG"|({letter}"."({letter}".")+|{upper}"."|{upper}{lcons}+".")

%s new_token

%%

  /* Sentence splitting */

("!"|"?"|"."){trail_end}?/{spnl}       {yyless(1); tok(1);}
{trail_end}                            {if (sent==1) {printf(" "); ECHO; printf(" ");} else {REJECT;}}
<new_token>{abbrev}/{end_nop}          {tok(0); printf(" ");}

  /* SGML entities */

&pound;                                {tok(0); printf(" ");}
{ns}/&percnt                           {tok(0); printf(" ");}
&{upper}*{lower}+{digit}*(;)?          tok(0);

  /* Contractions, possessives */

Dato/'{end}                                            {tok(0); printf(" ");}

  /* Leading punctuation */

``                                     {tok(0); printf(" ");}
{ns}[(\[$\xA3`"]                       tok(0);
`                                      {tok(0); printf("` ");}
["]                                    {if (sent==1) {printf(" "); ECHO; printf(" ");} else {REJECT;}}
[(\[$\xA3`"]                           {tok(0); printf(" ");}

  /* Trailing punctuation */

"."/"..."                              {tok(0); printf(" ");}
"..."                                  {printf(" "); tok(0); printf(" ");}
''/{end}                               {tok(0); printf(" ");}
{ns}"."/{trail_mid}{spnl}              {tok(0); printf(" ");}
{ns}"."/{trail_end}{spnl}              {yyless(1); tok(0); printf(" ");}
{ns}{trail_nop}+"."?/{spnl}            {yyless(1); tok(0); printf(" ");}
{ns}"."/{spnl}                         {yyless(1); tok(0); printf(" ");}

  /* Inside/outside a token */

{ns}                                   {tok(0); BEGIN(INITIAL);}
{sp}                                   {ECHO; BEGIN(new_token);}
{nl}                                   {ECHO; nl++; BEGIN(new_token);}

%%

int tok(int s)
{
  if (sent==1 || nl>1) /* last token indicated end of sentence. Or new para */
    {printf("^ ");}
  ECHO;
  sent=s; nl=0;
  BEGIN(new_token);
}

int main(int argc, char **argv) 
{ 
  BEGIN(new_token);
  printf("^ ");
  yylex();
}



