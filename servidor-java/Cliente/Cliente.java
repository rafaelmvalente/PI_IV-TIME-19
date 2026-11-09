// Caique Vasconcelos Naimi - 25004208
// Data: 09/11/2026
// Descrição: Cliente de teste do servidor de validação de telefone. Simula o que
// o backend (Node) vai fazer: enviar o telefone e ler o Resultado.

import java.net.*;
import java.io.*;

// TODO BACKEND (Node): este Cliente so existe para testar o Servidor.
// Quando o backend estiver pronto, ele fara exatamente o que este main faz:
//   1. abrir um socket em HOST_PADRAO:PORTA_PADRAO (localhost:3000);
//   2. enviar um PedidoDeValidacao com o telefone digitado no app;
//   3. enviar um PedidoDeResultado;
//   4. ler o Resultado (valido + mensagem) e devolver ao app;
//   5. enviar um PedidoParaSair ao terminar.
public class Cliente
{
	public static final String HOST_PADRAO  = "localhost";
	public static final int    PORTA_PADRAO = 3000;

	public static void main (String[] args)
	{
        if (args.length>2)
        {
            System.err.println ("Uso esperado: java Cliente [HOST [PORTA]]\n");
            return;
        }

        Socket conexao=null;
        try
        {
            String host = Cliente.HOST_PADRAO;
            int    porta= Cliente.PORTA_PADRAO;

            if (args.length>0)
                host = args[0];

            if (args.length==2)
                porta = Integer.parseInt(args[1]);

            conexao = new Socket (host, porta);
        }
        catch (Exception erro)
        {
            System.err.println ("Indique o servidor e a porta corretos!\n");
            return;
        }

        ObjectOutputStream transmissor=null;
        try
        {
            transmissor =
            new ObjectOutputStream(
            conexao.getOutputStream());
        }
        catch (Exception erro)
        {
            System.err.println ("Indique o servidor e a porta corretos!\n");
            return;
        }

        ObjectInputStream receptor=null;
        try
        {
            receptor =
            new ObjectInputStream(
            conexao.getInputStream());
        }
        catch (Exception erro)
        {
            System.err.println ("Indique o servidor e a porta corretos!\n");
            return;
        }

        Parceiro servidor=null;
        try
        {
            servidor =
            new Parceiro (conexao, receptor, transmissor);
        }
        catch (Exception erro)
        {
            System.err.println ("Indique o servidor e a porta corretos!\n");
            return;
        }

        TratadoraDeComunicadoDeDesligamento tratadoraDeComunicadoDeDesligamento = null;
        try
        {
			tratadoraDeComunicadoDeDesligamento = new TratadoraDeComunicadoDeDesligamento (servidor);
		}
		catch (Exception erro)
		{} // sei que servidor foi instanciado

        tratadoraDeComunicadoDeDesligamento.start();

        char opcao=' ';
        do
        {
            System.out.print ("Sua opcao ([V]alidar telefone, [T]erminar)? ");

            try
            {
				opcao = Character.toUpperCase(Teclado.getUmChar());
		    }
		    catch (Exception erro)
		    {
				System.err.println ("Opcao invalida!\n");
				continue;
			}

			if ("VT".indexOf(opcao)==-1)
		    {
				System.err.println ("Opcao invalida!\n");
				continue;
			}

			try
			{
				if (opcao=='V')
				{
					System.out.print ("Telefone? ");
					String telefone = Teclado.getUmString();
					System.out.println();

					servidor.receba (new PedidoDeValidacao (telefone));
					servidor.receba (new PedidoDeResultado ());
					Comunicado comunicado = null;
					do
					{
						comunicado = (Comunicado)servidor.espie ();
					}
					while (!(comunicado instanceof Resultado));
					Resultado resultado = (Resultado)servidor.envie ();
					System.out.println ("Resultado: "+resultado+"\n");
				}
			}
			catch (Exception erro)
			{
				System.err.println ("Erro de comunicacao com o servidor;");
				System.err.println ("Tente novamente!");
				System.err.println ("Caso o erro persista, termine o programa");
				System.err.println ("e volte a tentar mais tarde!\n");
			}
        }
        while (opcao != 'T');

		try
		{
			servidor.receba (new PedidoParaSair ());
		}
		catch (Exception erro)
		{}

		System.out.println ("Obrigado por usar este programa!");
		System.exit(0);
	}
}
