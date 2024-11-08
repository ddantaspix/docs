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


use materiais
go

create procedure ISC_SP_PROXIMO_DOCUMENTO_BUSCAR
(
	@sequencial	int output
)
as
begin
	--Número do próximo documento a ser gerado
	select	@sequencial = M02_TX_PARAMETRO
	from	MAT_M02_PARAMETROS
	where	M02_NR_PARAMETRO = 30
end
go

create procedure ISC_SP_MATERIAS_DOCUMENTO_INCLUIR
(
	@sequencial			int
	@material			char(08),
	@digitoVerificador	char(01),	
	@unidade			char(02),
	@quantidade			smallmoney,
	@cCustoAtende		char(05),
	@contaAtende		char(06),				
	@cCustoRecebe		char(05),
	@contaRecebe		char(06)	
)
as
begin
	insert MAT_M48_DOC_MATERIAIS_BAT 
	(
		M47_NR_SEQUENCIAL,
		M48_NR_POSICAO,
		L03_CD_MATERIAL,
		L03_NR_DV,
		M06_SG_UNIDADE,
		M48_NR_QUANTIDADE,
		M11_CD_CCUSTO_ATENDE,
		M11_NR_CONTA_ATENDE,
		M11_CD_CCUSTO_RECEBE,
		M11_NR_CONTA_RECEBE,
		M48_VL_UNITARIO_1,
		M48_VL_UNITARIO_2
	)
	values 
	(
		@sequencial
		1,--sequencial do registro dentro do @sequencial
		@material,
		@digitoVerificador,
		@unidade,
		@quantidade,
		@contaAtende,
		@cCustoAtende,
		@contaRecebe,
		@cCustoRecebe,
		0,
		0
	)
end
go

create procedure ISC_SP_DOCUMENTO_INCLUIR
(
	@sequencial			int,
	@natureza			int,
	@centroCustoAtende	char(05),
	@contaAtende		char(06),				
	@ccRecebe			char(05),
	@centroCustoRecebe	char(06),
	@cdUsuario			char(08)	
)
as
begin
	declare	@empresa	tinyint

	--busca a empresa do centro de custo e conta atende (almoxatrifado origem)
	select	distinct @empresa = M30_CD_EMPRESA
	from	materiais..MAT_M29_SALDOS M29
	inner join materiais..MAT_M07_CENTROS_CUSTO M07
	on		M29.M07_CD_CCUSTO = M07.M07_CD_CCUSTO
	where	M29.M07_CD_CCUSTO = @centroCustoAtende
	and		M29.M09_NR_CONTA  = @contaAtende
	and 	M07.M07_TP_CCUSTO = 'C'
	union
	--busca a empresa do centro de custo e conta recebe (almoxatrifado destino)
	select	distinct @empresa = M30_CD_EMPRESA
	from	MAT_M29_SALDOS M29
	inner join MAT_M07_CENTROS_CUSTO M07
	on		M29.M07_CD_CCUSTO = M07.M07_CD_CCUSTO
	where	M29.M07_CD_CCUSTO = @centroCustoRecebe
	and		M29.M09_NR_CONTA  = @contaRecebe
	and 	M07.M07_TP_CCUSTO = 'C'

	insert MAT_M47_DOCUMENTOS_BAT 
	(
		M47_NR_SEQUENCIAL,
		M03_NR_NATUREZA,
		M47_NR_DOCUMENTO, 
		M30_CD_EMPRESA,
		M47_DT_DIGITACAO,
		M47_DT_DOCUMENTO,
		M27_CD_USUARIO,
		M47_TX_OBSERVACAO,
		M47_ST_VALOR, 
		M47_VL_TOTAL_DOC,
		M47_ST_SITUACAO,
		M47_IN_REPROCESSO,
		M47_NR_NF_FORNECEDOR
	)
	values
	(
		@sequencial,
		@natureza
		@sequencial,
		@empresa
		convert(date, getdate()),
		convert(date, getdate()),
		@cdUsuario,
		'',
		'N',
		0,
		'N',
		'S',
		null
	)
end
go

create procedure ISC_SP_PROXIMO_DOCUMENTO_ATUALIZAR
(
	@sequencial	int
)
as
begin
	--atualiza o parâmetro com o próximo número de documento
	update	MAT_M02_PARAMETROS
	set		M02_tx_parametro = @sequencial + 1--próximo documento a ser gerado
	where	M02_NR_Parametro = 30
end
go