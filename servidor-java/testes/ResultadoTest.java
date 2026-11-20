// Nome: Vinicius Santuci Virgolino - RA: 25000294
// Data: 20/11/2026
// Descrição: Teste INTRACLASSE das classes Resultado e PedidoDeValidacao,
// com particionamento por ATRIBUTO. São classes que só carregam dados (não
// têm estado que muda nem cálculo), então cada teste escolhe um valor de cada
// partição dos atributos e confere getters, toString e a serialização (os
// objetos viajam pelo socket).

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

import java.io.*;

public class ResultadoTest
{
    // Partições dos atributos:
    //   Resultado.valido            -> true | false
    //   Resultado.mensagem          -> texto | vazia | null
    //   PedidoDeValidacao.telefone  -> formatado | só dígitos | vazio | null

    // ---------- Resultado ----------

    @Test
    void validoComMensagem ()
    {
        Resultado r = new Resultado (true, "Telefone valido");

        assertTrue   (r.getValido ());
        assertEquals ("Telefone valido", r.getMensagem ());
        assertEquals ("VALIDO - Telefone valido", r.toString ());
    }

    @Test
    void invalidoComMensagem ()
    {
        Resultado r = new Resultado (false, "DDD invalido");

        assertFalse  (r.getValido ());
        assertEquals ("DDD invalido", r.getMensagem ());
        assertEquals ("INVALIDO - DDD invalido", r.toString ());
    }

    @Test
    void mensagemVazia ()
    {
        Resultado r = new Resultado (false, "");

        assertEquals ("", r.getMensagem ());
        assertEquals ("INVALIDO - ", r.toString ());
    }

    // ANOMALIA: o construtor aceita mensagem null sem reclamar, e o toString
    // mostra a palavra "null" para quem ler o resultado.
    @Test
    void mensagemNula ()
    {
        Resultado r = new Resultado (true, null);

        assertNull   (r.getMensagem ());
        assertEquals ("VALIDO - null", r.toString ());
    }

    @Test
    void resultadoMantemAtributosAoPassarPeloSocket () throws Exception
    {
        Resultado r = (Resultado) serializeEVolte (new Resultado (false, "DDD invalido"));

        assertFalse  (r.getValido ());
        assertEquals ("DDD invalido", r.getMensagem ());
    }

    // ---------- PedidoDeValidacao ----------

    @Test
    void telefoneFormatado ()
    {
        PedidoDeValidacao p = new PedidoDeValidacao ("(19) 99999-8888");

        assertEquals ("(19) 99999-8888", p.getTelefone ());
        assertEquals ("(19) 99999-8888", p.toString ());
    }

    @Test
    void telefoneSoDigitos ()
    {
        PedidoDeValidacao p = new PedidoDeValidacao ("19999998888");

        assertEquals ("19999998888", p.getTelefone ());
    }

    @Test
    void telefoneVazio ()
    {
        PedidoDeValidacao p = new PedidoDeValidacao ("");

        assertEquals ("", p.getTelefone ());
        assertEquals ("", p.toString ());
    }

    // ANOMALIA: aceita telefone null; o erro só aparece depois, no servidor
    // ("Telefone ausente"), e o toString devolve a palavra "null".
    @Test
    void telefoneNulo ()
    {
        PedidoDeValidacao p = new PedidoDeValidacao (null);

        assertNull   (p.getTelefone ());
        assertEquals ("null", p.toString ());
    }

    @Test
    void pedidoMantemTelefoneAoPassarPeloSocket () throws Exception
    {
        PedidoDeValidacao p = (PedidoDeValidacao) serializeEVolte (new PedidoDeValidacao ("(19) 99999-8888"));

        assertEquals ("(19) 99999-8888", p.getTelefone ());
    }

    // Faz o mesmo que o socket: transforma o objeto em bytes e lê de volta.
    private static Object serializeEVolte (Object objeto) throws Exception
    {
        ByteArrayOutputStream bytes = new ByteArrayOutputStream ();
        ObjectOutputStream    saida = new ObjectOutputStream (bytes);
        saida.writeObject (objeto);
        saida.flush ();

        ObjectInputStream entrada = new ObjectInputStream (new ByteArrayInputStream (bytes.toByteArray ()));
        return entrada.readObject ();
    }
}
