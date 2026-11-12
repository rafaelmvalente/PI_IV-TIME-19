// Caique Vasconcelos Naimi - 25004208
// Data: 12/11/2026
// Descrição: Cliente sem teclado usado pelo backend (Node). Faz o mesmo que a
// opção [V] do Cliente: envia o PedidoDeValidacao e o PedidoDeResultado, lê o
// Resultado e sai com o PedidoParaSair. Imprime uma linha "VALIDO|mensagem" ou
// "INVALIDO|mensagem" e termina com o código 0 (válido), 1 (inválido) ou
// 2 (erro de comunicação com o servidor).
// Uso: java ValidaTelefone HOST PORTA TELEFONE
import java.net.*;
import java.io.*;

public class ValidaTelefone
{
	public static void main (String[] args)
	{
        if (args.length!=3)
        {
            System.err.println ("Uso esperado: java ValidaTelefone HOST PORTA TELEFONE");
            System.exit(2);
        }

        Parceiro servidor=null;
        try
        {
            Socket conexao = new Socket ();
            conexao.connect (new InetSocketAddress (args[0], Integer.parseInt(args[1])), 3000);
            conexao.setSoTimeout (5000); // não fica esperando para sempre um servidor travado

            ObjectOutputStream transmissor = new ObjectOutputStream (conexao.getOutputStream());
            ObjectInputStream  receptor    = new ObjectInputStream  (conexao.getInputStream());
            servidor = new Parceiro (conexao, receptor, transmissor);

            servidor.receba (new PedidoDeValidacao (args[2]));
            servidor.receba (new PedidoDeResultado ());

            Comunicado comunicado = servidor.envie ();
            if (!(comunicado instanceof Resultado))
                throw new Exception ("Servidor nao devolveu um Resultado");
            Resultado resultado = (Resultado)comunicado;

            try
            {
                servidor.receba (new PedidoParaSair ());
            }
            catch (Exception erro)
            {} // o resultado já chegou; sair é só educação com o servidor

            System.out.println ((resultado.getValido()?"VALIDO":"INVALIDO")+"|"+resultado.getMensagem());
            System.exit (resultado.getValido() ? 0 : 1);
        }
        catch (Exception erro)
        {
            System.err.println ("Erro de comunicacao com o servidor: "+erro.getMessage());
            System.exit(2);
        }
	}
}
