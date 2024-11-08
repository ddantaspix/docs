use apn
go
------------------------------------------------------------------------------------------------------------------------------
-- TABELAS
------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------
-- PROCEDURES e VIEWS
------------------------------------------------------------------------------------------------------------------------------
create procedure [dbo].[IDM_SP_ALMOXARIFADO_LOCAL_BUSCAR]
(
	@idAlmoxarifado int,
	@cdLocal		char(04)
)
as
begin
	select	A04_ID_LOCAL		as ID_LOCAL,
			A02_ID_ALMOX_PROCES	as ID_ALMOX_PROCES,
			A04_CD_LOCAL		as CD_LOCAL,
			A04_TX_DESCRICAO	as TX_DESCRICAO
	from	APN_A04_LOCAIS
	where	A02_ID_ALMOX_PROCES = @idAlmoxarifado
	and		A04_CD_LOCAL = @cdLocal
end
go

-------------------------------------------------------------------------------------------------------------------
create procedure [dbo].[IDM_SP_CAIXA_DEVOLUCAO_INCLUIR]
(
	@idEstoque					int,	
	@idAlmoxarifadoOrigem		int,
	@idAlmoxarifadoDestino		int,	
	@idLocal					int,
	@nrPesoLiquidoRequisitado	smallmoney,
	@nrPesoLiquidoDevolvido		smallmoney,
	@nrTara						smallmoney,
	@nrQtdeRequisitada			int,
	@nrQtdeDevolvida			int,
	@stParcial					tinyint,
	@cdUsuario					char(08)	
)
as
begin
	declare @ID_MOVIMENTO_DEVOLUCAO 				int = 5
	declare @ID_STATUS_CAIXA_DISPONIVEL 			char(01) = 'D'
	declare @ID_STATUS_CAIXA_AGUARDANDO_CONFIRMACAO char(01) = 'A'
	
	declare @idEstoqueNovo	int
	declare @nrPesoCaixa	smallmoney
	declare @nrCaixa		smallint	
	
	if (@stParcial = 1)
	begin	
		select	@idEstoqueNovo = isnull(max(isnull(A15_ID_ESTOQUE,0)),0) + 1 
		from 	APN_A15_ESTOQUES

		--insere a movimentação do tipo devolução com o peso líquido que esta sendo devolvido 
		--e a quantidade que foi requisitada
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
			A18_VL_BAIXA, 
			PP_TX_USER_STAMP
		)
		values 
		(
			@ID_MOVIMENTO_DEVOLUCAO, 
			@idEstoqueNovo, 
			@idAlmoxarifadoOrigem, 
			@idAlmoxarifadoDestino, 
			null, 
			convert(varchar(20),getdate(),101),
			@nrPesoLiquidoDevolvido, 
			@nrQtdeRequisitada, 
			'N', 
			null, 
			@cdUsuario
		)	
	
		select @nrPesoCaixa = 0
		select @nrCaixa = 1

		select	@nrPesoCaixa = isnull(A15.A15_NR_PESO_BRUTO,0) - isnull(A15.A15_NR_PESO_LIQUIDO,0),
				@nrCaixa = (
								select	isnull(max(isnull(A15a.A15_NR_CAIXA,0)),0) + 1 
								from	APN_A15_ESTOQUES A15a
								where	A15.A14_ID_ROMANEIO = A15a.A14_ID_ROMANEIO
							) 
		from	APN_A15_ESTOQUES A15
		where	A15.A15_ID_ESTOQUE = @idEstoque	

		--guarda no log a caixa requisitada com os pesos requisitados
		insert  APN_A15_ESTOQUES_LOG 
		(
			A15_ID_ESTOQUE, 
			A14_ID_ROMANEIO, 
			A02_ID_ALMOX_PROCES, 
			A04_ID_LOCAL, 
			A15_NR_CAIXA,
			A15_NR_PESO_BRUTO, 
			A15_NR_PESO_LIQUIDO,
			A15_NR_TARA, 
			A15_NR_QTDE, 
			A19_ST_PECA, 
			A15_NR_NUM_PECA, 
			PP_TM_TIME_STAMP,
			PP_TX_USER_STAMP, 
			A15_ST_IMPRESSO, 
			A15_ST_ALTERADA,
			A15_NR_NOVA_CAIXA
		)
		select	A15_ID_ESTOQUE, 
				A14_ID_ROMANEIO,
				A02_ID_ALMOX_PROCES, 
				A04_ID_LOCAL, 
				A15_NR_CAIXA, 
				A15_NR_PESO_BRUTO, 
				A15_NR_PESO_LIQUIDO,
				A15_NR_TARA, 
				A15_NR_QTDE, 
				A19_ST_PECA, 
				A15_NR_NUM_PECA, 
				getdate(), 
				@cdUsuario,			
				A15_ST_IMPRESSO, 
				A15_ST_ALTERADA, 
				@nrCaixa
		from	APN_A15_ESTOQUES
		where	A15_ID_ESTOQUE = @idEstoque			
			
		--atualiza a caixa requisitada anteriormente com o novo peso bruto e peso líquido(descontando o peso devolvido)
		update	APN_A15_ESTOQUES
		set		A15_NR_PESO_BRUTO = @nrPesoCaixa + (@nrPesoLiquidoRequisitado - @nrPesoLiquidoDevolvido),
				A15_NR_PESO_LIQUIDO = @nrPesoLiquidoRequisitado - @nrPesoLiquidoDevolvido,
				A19_ST_PECA = @ID_STATUS_CAIXA_DISPONIVEL,
				PP_TX_USER_STAMP = @cdUsuario,
				A15_ST_ALTERADA = 'S'
		where	A15_ID_ESTOQUE = @idEstoque
		
		--insere a nova caixa com o peso devolvido
		insert APN_A15_ESTOQUES 
		(
			A15_ID_ESTOQUE, 
			A14_ID_ROMANEIO, 
			A02_ID_ALMOX_PROCES, 
			A04_ID_LOCAL, 
			A15_NR_CAIXA, 
			A15_NR_PESO_BRUTO, 
			A15_NR_PESO_LIQUIDO,
			A15_NR_TARA, 
			A15_NR_QTDE, 
			A19_ST_PECA, 
			A15_NR_NUM_PECA, 
			PP_TM_TIME_STAMP, 
			PP_TX_USER_STAMP, 
			A15_ST_IMPRESSO, 
			A15_ST_ALTERADA
		)
		select	@idEstoqueNovo, 
				A14_ID_ROMANEIO, 
				@idAlmoxarifadoDestino, 
				@idLocal, 
				@nrCaixa, 
				(@nrPesoLiquidoDevolvido + @nrTara), 
				@nrPesoLiquidoDevolvido,
				@nrTara, 
				@nrQtdeDevolvida, 
				@ID_STATUS_CAIXA_AGUARDANDO_CONFIRMACAO, 
				A15_NR_NUM_PECA, 
				getdate(), 
				@cdUsuario, 
				A15_ST_IMPRESSO,
				'N'
		from 	APN_A15_ESTOQUES
		where 	A15_ID_ESTOQUE = @idEstoque		
		
	end
	else
	begin
		--insere a movimentação do tipo devolução com o peso líquido que esta sendo devolvido 
		--e a quantidade que foi requisitada, com o idEstoque original
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
			A18_VL_BAIXA, 
			PP_TX_USER_STAMP
		)
		values 
		(
			@ID_MOVIMENTO_DEVOLUCAO, 
			@idEstoque, 
			@idAlmoxarifadoOrigem, 
			@idAlmoxarifadoDestino, 
			null, 
			convert(varchar(20),getdate(),101),
			@nrPesoLiquidoDevolvido, 
			@nrQtdeRequisitada, 
			'N', 
			null, 
			@cdUsuario
		)	
	
		--volta a caixa para o almoxarifado de onde a requisição solicitou a caixa
		update	APN_A15_ESTOQUES
		set		A02_ID_ALMOX_PROCES = @idAlmoxarifadoDestino,
				A04_ID_LOCAL = @idLocal,
				A19_ST_PECA = @ID_STATUS_CAIXA_AGUARDANDO_CONFIRMACAO,
				PP_TX_USER_STAMP = @cdUsuario,
				A25_CD_APLICACAO_FIO = null,
				A24_CD_LOCAL_FIO = null,
				A15_DT_DATA_STATUS = null
		where	A15_ID_ESTOQUE = @idEstoque
	end
end
go

------------------------------------------------------------------------------------------------------------------------------
-- INSERTS E UPDATES
------------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------------
-- ATUALIZAÇÃO VERSÃO
------------------------------------------------------------------------------------------------------------------------------
begin transaction



update	SCO_C00_VERSAO_BANCO_DADOS
set		C00_NR_MAJOR_VERSION = 1,
		C00_NR_MINOR_VERSION = 0,
		C00_NR_REVISION = 2

--commit transaction
--rollback transaction
