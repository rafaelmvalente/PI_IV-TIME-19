// Nome: Vinicius Santuci Virgolino - RA: 25000294
// Data: 20/11/2026
// Descrição: Teste INTERCLASSE do principal serviço do servidor Java: validar
// um telefone. O teste sobe o servidor de verdade (AceitadoraDeConexao) na
// porta 3101 e faz o papel do cliente (como o ValidaTelefone usado pelo
// backend): conecta pelo socket, envia PedidoDeValidacao e PedidoDeResultado,
// recebe o Resultado e sai com PedidoParaSair. Assim passam pelo teste as
// classes AceitadoraDeConexao, SupervisoraDeConexao, Parceiro, Comunicado e
// suas filhas. Segue o diagrama de sequência do cenário NORMAL (item g).

import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

import java.io.*;
import java.net.*;
import java.util.ArrayList;

public class ServidorInterclasseTest
{
    private static final String PORTA = "3101";   // diferente da 3001 para não brigar com o servidor real

    private static ArrayList<Parceiro> usuarios = new ArrayList<Parceiro> ();

    // Passos 1 e 2 do diagrama: cria a AceitadoraDeConexao e inicia a thread.
    @BeforeAll
    static void subaOServidor () throws Exception
    {
        AceitadoraDeConexao aceitadora = new AceitadoraDeConexao (PORTA, usuarios);
        aceitadora.setDaemon (true);   // a thread acaba junto com os testes
        aceitadora.start ();
    }

    // ---------- Cenário NORMAL ----------

    @Test
    void telefoneValidoDevolveResultadoValido () throws Exception
    {
        Parceiro servidor = conecte ();                               // passos 3 a 8

        servidor.receba (new PedidoDeValidacao ("(19) 99999-8888"));  // passo 9
        servidor.receba (new PedidoDeResultado ());                   // passo 13

        Comunicado resposta = servidor.envie ();                      // passos 19 e 20

        assertTrue (resposta instanceof Resultado);
        Resultado resultado = (Resultado) resposta;
        assertTrue   (resultado.getValido ());                        // passo 21
        assertEquals ("Telefone valido", resultado.getMensagem ());

        servidor.receba (new PedidoParaSair ());                      // passo 22
        confiraQueOServidorTirouOUsuario ();                          // passo 25
    }

    // ---------- Cenários ALTERNATIVOS ----------

    @Test
    void dddInvalidoDevolveResultadoInvalido () throws Exception
    {
        Parceiro servidor = conecte ();

        servidor.receba (new PedidoDeValidacao ("(20) 99999-8888"));
        servidor.receba (new PedidoDeResultado ());

        Resultado resultado = (Resultado) servidor.envie ();
        assertFalse  (resultado.getValido ());
        assertEquals ("DDD invalido", resultado.getMensagem ());

        servidor.receba (new PedidoParaSair ());
        confiraQueOServidorTirouOUsuario ();
    }

    @Test
    void pedirResultadoSemMandarTelefoneDevolveTelefoneAusente () throws Exception
    {
        Parceiro servidor = conecte ();

        servidor.receba (new PedidoDeResultado ());   // pula o PedidoDeValidacao

        Resultado resultado = (Resultado) servidor.envie ();
        assertFalse  (resultado.getValido ());
        assertEquals ("Telefone ausente", resultado.getMensagem ());

        servidor.receba (new PedidoParaSair ());
        confiraQueOServidorTirouOUsuario ();
    }

    // ---------- Cenários de ERRO (exceções) ----------

    @Test
    void portaInvalidaLancaExcecao ()
    {
        Exception erro = assertThrows (Exception.class,
            () -> new AceitadoraDeConexao ("abc", new ArrayList<Parceiro> ()));

        assertEquals ("Porta invalida", erro.getMessage ());
    }

    @Test
    void portaAusenteLancaExcecao ()
    {
        Exception erro = assertThrows (Exception.class,
            () -> new AceitadoraDeConexao (null, new ArrayList<Parceiro> ()));

        assertEquals ("Porta ausente", erro.getMessage ());
    }

    // FALHA: a AceitadoraDeConexao abre o ServerSocket ANTES de conferir se a
    // lista de usuários é nula. Com lista nula ela lança "Usuarios ausentes",
    // mas a porta fica ocupada, e uma nova tentativa (agora correta) na mesma
    // porta falha com "Porta invalida".
    // Melhoria: conferir os parâmetros antes de abrir o ServerSocket.
    @Disabled ("FALHA na AceitadoraDeConexao: com usuarios nulo a porta fica ocupada")
    @Test
    void usuariosNuloNaoDeveDeixarAPortaOcupada ()
    {
        Exception erro = assertThrows (Exception.class,
            () -> new AceitadoraDeConexao ("3102", null));
        assertEquals ("Usuarios ausentes", erro.getMessage ());

        assertDoesNotThrow (() -> new AceitadoraDeConexao ("3102", new ArrayList<Parceiro> ()));
    }

    // ---------- Auxiliares ----------

    // Faz o que o cliente (ValidaTelefone) faz: conecta e monta o Parceiro.
    private static Parceiro conecte () throws Exception
    {
        Socket conexao = new Socket ("localhost", Integer.parseInt (PORTA));
        conexao.setSoTimeout (5000);   // se o servidor travar, o teste falha em vez de ficar esperando

        ObjectOutputStream transmissor = new ObjectOutputStream (conexao.getOutputStream ());
        ObjectInputStream  receptor    = new ObjectInputStream  (conexao.getInputStream ());

        return new Parceiro (conexao, receptor, transmissor);
    }

    // Depois do PedidoParaSair a SupervisoraDeConexao tira o usuário da lista.
    // Como isso acontece em outra thread, espera até 2 segundos.
    private static void confiraQueOServidorTirouOUsuario () throws Exception
    {
        for (int i = 0; i < 20; i++)
        {
            synchronized (usuarios)
            {
                if (usuarios.isEmpty ())
                    return;
            }
            Thread.sleep (100);
        }
        fail ("O servidor não tirou o usuário da lista depois do PedidoParaSair");
    }
}
