// Nome: Vinicius Santuci Virgolino - RA: 25000294
// Data: 20/11/2026
// Descrição: Teste INTRACLASSE da classe Parceiro, com particionamento por
// ESTADO. O Parceiro guarda o próximo comunicado já lido (proximoComunicado)
// e pode estar com a conexão aberta ou fechada, então os testes passam por
// cada estado e por cada transição entre eles. Os streams ficam em memória
// (sem rede), para o teste não depender de servidor rodando.

import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

import java.io.*;
import java.net.*;
import java.time.Duration;

public class ParceiroTest
{
    // Estados do Parceiro:
    //   VAZIO    -> aberto, sem comunicado guardado (proximoComunicado == null)
    //   PENDENTE -> aberto, com comunicado já espiado e guardado
    //   FECHADO  -> depois do adeus()
    //
    // Transições testadas:
    //   VAZIO    --espie()-->  PENDENTE  (lê do stream e guarda)
    //   PENDENTE --espie()-->  PENDENTE  (devolve o mesmo, sem ler de novo)
    //   PENDENTE --envie()-->  VAZIO     (devolve o guardado e esvazia)
    //   VAZIO    --envie()-->  VAZIO     (lê do stream e devolve direto)
    //   VAZIO    --receba()--> VAZIO     (escreve no stream de saída)
    //   VAZIO    --adeus()-->  FECHADO
    //   FECHADO  --receba()--> exceção "Erro de transmissao"

    // ---------- Construtor (pré-condições) ----------

    @Test
    void construtorSemConexaoLancaExcecao () throws Exception
    {
        Exception erro = assertThrows (Exception.class,
            () -> new Parceiro (null, entradaCom (), new ObjectOutputStream (new SaidaEmMemoria ())));

        assertEquals ("Conexao ausente", erro.getMessage ());
    }

    @Test
    void construtorSemReceptorLancaExcecao () throws Exception
    {
        Exception erro = assertThrows (Exception.class,
            () -> new Parceiro (new Socket (), null, new ObjectOutputStream (new SaidaEmMemoria ())));

        assertEquals ("Receptor ausente", erro.getMessage ());
    }

    @Test
    void construtorSemTransmissorLancaExcecao () throws Exception
    {
        Exception erro = assertThrows (Exception.class,
            () -> new Parceiro (new Socket (), entradaCom (), null));

        assertEquals ("Transmissor ausente", erro.getMessage ());
    }

    // ---------- Estado VAZIO ----------

    @Test
    void vazioEnvieLeDoStreamEContinuaVazio () throws Exception
    {
        Parceiro p = parceiroLendo (new PedidoDeValidacao ("19999998888"), new PedidoDeResultado ());

        Comunicado primeiro = p.envie ();
        Comunicado segundo  = p.envie ();   // se tivesse guardado o primeiro, viria ele de novo

        assertTrue (primeiro instanceof PedidoDeValidacao);
        assertTrue (segundo  instanceof PedidoDeResultado);
    }

    @Test
    void vazioRecebaEscreveNoStreamDeSaida () throws Exception
    {
        SaidaEmMemoria saida = new SaidaEmMemoria ();
        Parceiro p = new Parceiro (new Socket (), entradaCom (), new ObjectOutputStream (saida));

        p.receba (new Resultado (true, "Telefone valido"));

        Resultado lido = (Resultado) saida.leiaObjeto ();
        assertTrue   (lido.getValido ());
        assertEquals ("Telefone valido", lido.getMensagem ());
    }

    @Test
    void vazioSemNadaParaLerLancaErroDeRecepcao () throws Exception
    {
        Parceiro p = parceiroLendo ();   // stream sem nenhum comunicado

        Exception erro = assertThrows (Exception.class, () -> p.envie ());
        assertEquals ("Erro de recepcao", erro.getMessage ());
    }

    // ---------- VAZIO -> PENDENTE e estado PENDENTE ----------

    @Test
    void espieGuardaOComunicadoSemConsumir () throws Exception
    {
        Parceiro p = parceiroLendo (new PedidoDeValidacao ("19999998888"), new PedidoDeResultado ());

        Comunicado espiado      = p.espie ();
        Comunicado espiadoDeNovo = p.espie ();

        assertTrue (espiado instanceof PedidoDeValidacao);
        assertSame (espiado, espiadoDeNovo);   // não leu o segundo do stream
    }

    @Test
    void pendenteEnvieDevolveOGuardadoEVoltaParaVazio () throws Exception
    {
        Parceiro p = parceiroLendo (new PedidoDeValidacao ("19999998888"), new PedidoDeResultado ());

        Comunicado espiado  = p.espie ();
        Comunicado enviado  = p.envie ();   // PENDENTE -> VAZIO
        Comunicado proximo  = p.envie ();   // VAZIO: agora lê o segundo

        assertSame (espiado, enviado);
        assertTrue (proximo instanceof PedidoDeResultado);
    }

    // ---------- Estado FECHADO ----------

    @Test
    void fechadoRecebaLancaErroDeTransmissao () throws Exception
    {
        Parceiro p = new Parceiro (new Socket (), entradaCom (), new ObjectOutputStream (new SaidaEmMemoria ()));

        p.adeus ();   // VAZIO -> FECHADO

        Exception erro = assertThrows (Exception.class, () -> p.receba (new PedidoParaSair ()));
        assertEquals ("Erro de transmissao", erro.getMessage ());
    }

    // FALHA: se a leitura dá erro dentro do espie(), o semáforo (mutEx) é
    // adquirido e nunca liberado. A segunda chamada de espie() fica travada
    // para sempre em vez de lançar "Erro de recepcao" de novo.
    // Melhoria: liberar o mutEx num bloco finally.
    @Disabled ("FALHA no Parceiro.espie(): o mutEx não é liberado quando a leitura dá erro (o teste trava)")
    @Test
    void espieComErroNaoDeveTravarAProximaChamada () throws Exception
    {
        Parceiro p = parceiroLendo ();   // nada para ler -> erro

        assertThrows (Exception.class, () -> p.espie ());

        assertTimeoutPreemptively (Duration.ofSeconds (2), () ->
        {
            Exception erro = assertThrows (Exception.class, () -> p.espie ());
            assertEquals ("Erro de recepcao", erro.getMessage ());
        });
    }

    // ---------- Auxiliares ----------

    // Parceiro que, ao ler, recebe os comunicados dados (na ordem).
    private static Parceiro parceiroLendo (Comunicado... comunicados) throws Exception
    {
        return new Parceiro (new Socket (), entradaCom (comunicados), new ObjectOutputStream (new SaidaEmMemoria ()));
    }

    // Monta um ObjectInputStream em memória já contendo os comunicados.
    private static ObjectInputStream entradaCom (Comunicado... comunicados) throws Exception
    {
        ByteArrayOutputStream bytes = new ByteArrayOutputStream ();
        ObjectOutputStream    saida = new ObjectOutputStream (bytes);
        for (Comunicado c : comunicados)
            saida.writeObject (c);
        saida.flush ();

        return new ObjectInputStream (new ByteArrayInputStream (bytes.toByteArray ()));
    }

    // Saída em memória que se comporta como a de um socket: depois de
    // fechada, escrever nela dá IOException.
    private static class SaidaEmMemoria extends OutputStream
    {
        private ByteArrayOutputStream bytes   = new ByteArrayOutputStream ();
        private boolean               fechada = false;

        @Override
        public void write (int b) throws IOException
        {
            if (fechada)
                throw new IOException ("Stream fechado");
            bytes.write (b);
        }

        @Override
        public void flush () throws IOException
        {
            if (fechada)
                throw new IOException ("Stream fechado");
        }

        @Override
        public void close ()
        {
            fechada = true;
        }

        Object leiaObjeto () throws Exception
        {
            return new ObjectInputStream (new ByteArrayInputStream (bytes.toByteArray ())).readObject ();
        }
    }
}
