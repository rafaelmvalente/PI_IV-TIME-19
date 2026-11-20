// Nome: Vinicius Santuci Virgolino - RA: 25000294
// Data: 20/11/2026
// Descrição: Teste INTRACLASSE da classe SupervisoraDeConexao, com
// particionamento por CATEGORIA DE MÉTODOS. A classe tem o cálculo principal
// do servidor (valideTelefone), então os testes separam os métodos em
// categorias (construtor e cálculo) e escolhem casos válidos, inválidos e de
// limite. O valideTelefone é privado, por isso é chamado por reflexão (sem
// alterar o código do servidor). O run() precisa de socket e de outras
// classes, por isso fica no teste INTERCLASSE.

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

import java.lang.reflect.Method;
import java.net.Socket;
import java.util.ArrayList;

public class SupervisoraDeConexaoTest
{
    // Categorias de métodos:
    //   CONSTRUTOR -> valida os parâmetros (conexão e lista de usuários)
    //   CÁLCULO    -> valideTelefone: limpa o texto, tira o +55, confere
    //                 quantidade de dígitos, DDD e o primeiro dígito
    //   COMUNICAÇÃO (run) -> coberto no ServidorInterclasseTest
    //
    // Partições do cálculo:
    //   válidos   -> celular (11 dígitos), fixo (10 dígitos), com +55, com máscara
    //   inválidos -> null, vazio, tamanho errado, DDD inexistente,
    //                celular sem 9, fixo começando fora de 2 a 5
    //   limites   -> primeiro/último DDD, DDD inexistente no meio da faixa,
    //                fixo começando com 2 e com 5, fixo começando com 1 e com 6

    // ---------- CONSTRUTOR ----------

    @Test
    void construtorSemConexaoLancaExcecao ()
    {
        Exception erro = assertThrows (Exception.class,
            () -> new SupervisoraDeConexao (null, new ArrayList<Parceiro> ()));

        assertEquals ("Conexao ausente", erro.getMessage ());
    }

    @Test
    void construtorSemUsuariosLancaExcecao ()
    {
        Exception erro = assertThrows (Exception.class,
            () -> new SupervisoraDeConexao (new Socket (), null));

        assertEquals ("Usuarios ausentes", erro.getMessage ());
    }

    @Test
    void construtorComParametrosCertosNaoLanca ()
    {
        assertDoesNotThrow (() -> new SupervisoraDeConexao (new Socket (), new ArrayList<Parceiro> ()));
    }

    // ---------- CÁLCULO: telefones válidos ----------

    @Test
    void celularComMascaraEhValido () throws Exception
    {
        confiraValido ("(19) 99999-8888");
    }

    @Test
    void celularSoDigitosEhValido () throws Exception
    {
        confiraValido ("19999998888");
    }

    @Test
    void fixoComMascaraEhValido () throws Exception
    {
        confiraValido ("(19) 3333-4444");
    }

    @Test
    void celularComMais55EhValido () throws Exception
    {
        confiraValido ("+55 19 99999-8888");   // 13 dígitos -> tira o 55
    }

    @Test
    void fixoComMais55EhValido () throws Exception
    {
        confiraValido ("+55 19 3333-4444");    // 12 dígitos -> tira o 55
    }

    // ---------- CÁLCULO: telefones inválidos ----------

    @Test
    void telefoneNuloEhAusente () throws Exception
    {
        confiraInvalido (null, "Telefone ausente");
    }

    @Test
    void telefoneVazioTemTamanhoErrado () throws Exception
    {
        confiraInvalido ("", "Telefone deve ter DDD + 8 ou 9 digitos");
    }

    @Test
    void telefoneCurtoTemTamanhoErrado () throws Exception
    {
        confiraInvalido ("19 9999", "Telefone deve ter DDD + 8 ou 9 digitos");
    }

    @Test
    void telefoneLongoSem55TemTamanhoErrado () throws Exception
    {
        confiraInvalido ("199999988881", "Telefone deve ter DDD + 8 ou 9 digitos");   // 12 dígitos
    }

    @Test
    void dddInexistenteEhInvalido () throws Exception
    {
        confiraInvalido ("(20) 99999-8888", "DDD invalido");
    }

    @Test
    void celularSemNoveEhInvalido () throws Exception
    {
        confiraInvalido ("(19) 89999-8888", "Celular deve comecar com 9");
    }

    @Test
    void fixoComecandoComNoveEhInvalido () throws Exception
    {
        confiraInvalido ("(19) 9333-4444", "Telefone fixo deve comecar com 2, 3, 4 ou 5");
    }

    // ---------- CÁLCULO: limites ----------

    @Test
    void primeiroDddDaListaEhValido () throws Exception
    {
        confiraValido ("(11) 99999-8888");
    }

    @Test
    void ultimoDddDaListaEhValido () throws Exception
    {
        confiraValido ("(99) 99999-8888");
    }

    @Test
    void dddQueNaoExisteNoMeioDaFaixaEhInvalido () throws Exception
    {
        confiraInvalido ("(23) 99999-8888", "DDD invalido");   // existem 22 e 24, mas não 23
    }

    @Test
    void fixoComecandoComDoisEhValido () throws Exception
    {
        confiraValido ("(19) 2333-4444");   // menor permitido
    }

    @Test
    void fixoComecandoComCincoEhValido () throws Exception
    {
        confiraValido ("(19) 5333-4444");   // maior permitido
    }

    @Test
    void fixoComecandoComUmEhInvalido () throws Exception
    {
        confiraInvalido ("(19) 1333-4444", "Telefone fixo deve comecar com 2, 3, 4 ou 5");   // logo abaixo
    }

    @Test
    void fixoComecandoComSeisEhInvalido () throws Exception
    {
        confiraInvalido ("(19) 6333-4444", "Telefone fixo deve comecar com 2, 3, 4 ou 5");   // logo acima
    }

    // ANOMALIA: tudo que não é dígito é apagado antes da validação, então um
    // texto com letras no meio passa como telefone válido.
    // Melhoria: aceitar só dígitos, espaço, parênteses, hífen e "+".
    @Test
    void textoComLetrasPassaComoValido () throws Exception
    {
        confiraValido ("tel19abc99999-8888xyz");
    }

    // ---------- Auxiliares ----------

    private static void confiraValido (String telefone) throws Exception
    {
        Resultado r = valide (telefone);

        assertTrue   (r.getValido (), "deveria ser válido: " + telefone + " -> " + r);
        assertEquals ("Telefone valido", r.getMensagem ());
    }

    private static void confiraInvalido (String telefone, String mensagemEsperada) throws Exception
    {
        Resultado r = valide (telefone);

        assertFalse  (r.getValido (), "deveria ser inválido: " + telefone);
        assertEquals (mensagemEsperada, r.getMensagem ());
    }

    // Chama o método privado valideTelefone por reflexão.
    private static Resultado valide (String telefone) throws Exception
    {
        SupervisoraDeConexao supervisora = new SupervisoraDeConexao (new Socket (), new ArrayList<Parceiro> ());

        Method metodo = SupervisoraDeConexao.class.getDeclaredMethod ("valideTelefone", String.class);
        metodo.setAccessible (true);

        return (Resultado) metodo.invoke (supervisora, telefone);
    }
}
