// Caique Vasconcelos Naimi - 25004208
// Data: 09/11/2026
// Descrição: Thread do cliente que fica escutando o servidor e encerra o programa
// quando recebe um ComunicadoDeDesligamento.
// Baseado no modelo do professor (Fazedor de Continhas).

import java.net.*;

public class TratadoraDeComunicadoDeDesligamento extends Thread
{
    private Parceiro servidor;

    public TratadoraDeComunicadoDeDesligamento (Parceiro servidor) throws Exception
    {
        if (servidor==null)
            throw new Exception ("Porta invalida");

        this.servidor = servidor;
    }

    public void run ()
    {
        for(;;)
        {
			try
			{
				if (this.servidor.espie() instanceof ComunicadoDeDesligamento)
				{
					System.out.println ("\nO servidor vai ser desligado agora;");
				    System.err.println ("volte mais tarde!\n");
				    System.exit(0);
				}
			}
			catch (Exception erro)
			{}
        }
    }
}
