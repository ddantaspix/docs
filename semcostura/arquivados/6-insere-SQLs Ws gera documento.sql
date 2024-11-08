/*
********************************************************************************************************************************
												Geração de Documentos
********************************************************************************************************************************
*/
0)nome rotina WS
receberá os parâmetros: 
						material		char(08)
						unidade			char(02)
						quantidade		smallmoney
						natureza		int
						ccAtende		char(05)
						contaAtende		char(06)				
						ccRecebe		char(05)
						contaRecebe		char(06)
						observacao		varchar(30)
						cdUsuario		char(08)
						
						
1) Converter a função Calcula_DV para C#, essa função receberá como parâmetro o código do material
e retornará o dígito verificar que será um dos parâmetros passados na SP 


Public Function Calcula_DV(ByVal mskCdMaterial As String) As Integer

    If Len(Trim(mskCdMaterial)) = 7 Then
        mskCdMaterial = "0" & mskCdMaterial
    End If
 
    Static peso1(1 To 8)
    Static peso2(1 To 9)
    Dim i%, valor_aux%, str_codigo$, DV1%, dig_ver%
 
    peso1(1) = 4
    peso1(2) = 3
    peso1(3) = 8
    peso1(4) = 7
    peso1(5) = 6
    peso1(6) = 5
    peso1(7) = 4
    peso1(8) = 3
    
    peso2(1) = 5
    peso2(2) = 4
    peso2(3) = 3
    peso2(4) = 8
    peso2(5) = 7
    peso2(6) = 6
    peso2(7) = 5
    peso2(8) = 4
    peso2(9) = 3
 
    For i% = 1 To 8
        str_codigo$ = Mid$(mskCdMaterial, i%, 1)
        If str_codigo$ >= "0" And str_codigo$ <= "9" Then
            valor_aux% = Val(str_codigo$)
        ElseIf str_codigo$ >= "A" And str_codigo$ <= "I" Then
            valor_aux% = Asc(str_codigo$) - Asc("A") + 1
        ElseIf str_codigo$ >= "J" And str_codigo$ <= "R" Then
            valor_aux% = Asc(str_codigo$) - Asc("J") + 1
        ElseIf str_codigo$ >= "S" And str_codigo$ <= "Z" Then
            valor_aux% = Asc(str_codigo$) - Asc("S") + 2
        End If
        dig_ver% = dig_ver% + valor_aux% * peso1(i%)
    Next i%
 
    dig_ver% = dig_ver% Mod 10
    DV1% = dig_ver%
 
    dig_ver% = 0
    For i% = 1 To 8
        str_codigo$ = Mid$(mskCdMaterial, i%, 1)
        If str_codigo$ >= "0" And str_codigo$ <= "9" Then
            valor_aux% = Val(str_codigo$)
        ElseIf str_codigo$ >= "A" And str_codigo$ <= "I" Then
            valor_aux% = Asc(str_codigo$) - Asc("A") + 1
        ElseIf str_codigo$ >= "J" And str_codigo$ <= "R" Then
            valor_aux% = Asc(str_codigo$) - Asc("J") + 1
        ElseIf str_codigo$ >= "S" And str_codigo$ <= "Z" Then
            valor_aux% = Asc(str_codigo$) - Asc("S") + 2
        End If
        dig_ver% = dig_ver% + valor_aux% * peso2(i%)
    Next i%
    dig_ver% = dig_ver% + (DV1% * peso2(9))
 
    Calcula_DV% = dig_ver% Mod 10
 
End Function						
										

2) Bloquear entidade
sistema: 		MAT
entidade:		NUM_SEQ
modo bloqueio:	R
chave: 			30

3)Geração do documento
Definir dígito verificador material
Iniciar transação
Chamar a sp materiais..ISC_SP_DOCUMENTOS_GERAR
Finalizar transação

4)Liberar bloqueio de entidade
sistema: 		MAT
entidade:		NUM_SEQ
modo bloqueio:	R
chave: 			30

