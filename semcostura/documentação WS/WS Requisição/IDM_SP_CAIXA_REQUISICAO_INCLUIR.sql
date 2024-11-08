use apn
go  
------------------------------------------------------------------------------------------  
create procedure [dbo].[IDM_SP_CAIXA_REQUISICAO_INCLUIR]  
(  
	@idMovimento			int,
	@idEstoque				int,
	@idAlmoxarifadoOrigem	int,
	@idAlmoxarifadoDestino	int,
	@cdUsuario				char(08),
	@idMovimentacao 		int output
)  
as
begin
	declare @ID_STATUS_PECA_AGUARDANDO_CONFIRMACAO char(01) = 'A'
	
	insert APN_A18_MOVIMENTACOES 
	(
		A09_ID_MOVIMENTO, 
		A15_ID_ESTOQUE, 
		A18_ID_ALMOX_ORIGEM, 
		A18_ID_ALMOX_DESTINO, 
		A11_ID_MOTIVO, 
		A18_DT_MOVIMENTO,
		A18_NR_PESO_LIQUIDO, 
		A18_NR_QTDE_EMBALAGEM, 
		A18_ST_EXPORTA_MATERIAIS, 
		PP_TX_USER_STAMP, 
		A18_ST_LIBERADO_MATERIAIS
	) 
	select	@idMovimento, 
			A15_ID_ESTOQUE, 
			@idAlmoxarifadoOrigem, 
			@idAlmoxarifadoDestino, 
			null, 
			convert(varchar(20),getdate(),101),
			A15_NR_PESO_LIQUIDO, 
			A15_NR_QTDE, 
			'N', 
			@cdUsuario,
			'N'
	from	APN_A15_ESTOQUES		
	where	A15_ID_ESTOQUE = @idEstoque
	
	select	@idMovimentacao = @@IDENTITY	
		
	update	APN_A15_ESTOQUES
	set		A02_ID_ALMOX_PROCES = @idAlmoxarifadoDestino,
			A19_ST_PECA = @ID_STATUS_PECA_AGUARDANDO_CONFIRMACAO,
			PP_TX_USER_STAMP = @cdUsuario
	where	A15_ID_ESTOQUE = @idEstoque
end
go