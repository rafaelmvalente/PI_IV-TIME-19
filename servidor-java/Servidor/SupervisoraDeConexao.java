// Caique Vasconcelos Naimi - 25004208
// Data: 09/11/2026
// Descrição: Thread que atende um cliente conectado: recebe cada PedidoDeValidacao,
// valida o telefone (DDD, quantidade de dígitos, celular/fixo) e devolve um Resultado.
// Baseado no modelo do professor (Fazedor de Continhas).

import java.io.*;
import java.net.*;
import java.util.*;

public class SupervisoraDeConexao extends Thread
{
    // DDDs validos no Brasil (Anatel)
    private static final String DDDS_VALIDOS =
    " 11 12 13 14 15 16 17 18 19 21 22 24 27 28 31 32 33 34 35 37 38" +
    " 41 42 43 44 45 46 47 48 49 51 53 54 55 61 62 63 64 65 66 67 68 69" +
    " 71 73 74 75 77 79 81 82 83 84 85 86 87 88 89 91 92 93 94 95 96 97 98 99 ";

    private Parceiro            usuario;
    private Socket              conexao;
    private ArrayList<Parceiro> usuarios;

    public SupervisoraDeConexao
    (Socket conexao, ArrayList<Parceiro> usuarios)
    throws Exception
    {
        if (conexao==null)
            throw new Exception ("Conexao ausente");

        if (usuarios==null)
            throw new Exception ("Usuarios ausentes");

        this.conexao  = conexao;
        this.usuarios = usuarios;
    }

    // Aceita: (19) 99999-8888, 19999998888, +55 19 3333-4444 etc.
    private Resultado valideTelefone (String telefone)
    {
        if (telefone==null)
            return new Resultado (false, "Telefone ausente");

        String digitos = telefone.replaceAll ("[^0-9]", "");

        if (digitos.startsWith("55") && (digitos.length()==12 || digitos.length()==13))
            digitos = digitos.substring (2);

        if (digitos.length()!=10 && digitos.length()!=11)
            return new Resultado (false, "Telefone deve ter DDD + 8 ou 9 digitos");

        if (DDDS_VALIDOS.indexOf(" "+digitos.substring(0,2)+" ")==-1)
            return new Resultado (false, "DDD invalido");

        char primeiro = digitos.charAt(2);

        if (digitos.length()==11 && primeiro!='9')
            return new Resultado (false, "Celular deve comecar com 9");

        if (digitos.length()==10 && (primeiro<'2' || primeiro>'5'))
            return new Resultado (false, "Telefone fixo deve comecar com 2, 3, 4 ou 5");

        return new Resultado (true, "Telefone valido");
    }

    public void run ()
    {

        ObjectOutputStream transmissor;
        try
        {
            transmissor =
            new ObjectOutputStream(
            this.conexao.getOutputStream());
        }
        catch (Exception erro)
        {
            return;
        }

        ObjectInputStream receptor=null;
        try
        {
            receptor=
            new ObjectInputStream(
            this.conexao.getInputStream());
        }
        catch (Exception err0)
        {
            try
            {
                transmissor.close();
            }
            catch (Exception falha)
            {} // so tentando fechar antes de acabar a thread

            return;
        }

        try
        {
            this.usuario =
            new Parceiro (this.conexao,
                          receptor,
                          transmissor);
        }
        catch (Exception erro)
        {} // sei que passei os parametros corretos

        try
        {
            synchronized (this.usuarios)
            {
                this.usuarios.add (this.usuario);
            }


            for(;;)
            {
                Comunicado comunicado = this.usuario.envie ();

                if (comunicado==null)
                    return;
                else if (comunicado instanceof PedidoDeValidacao)
                {
					PedidoDeValidacao pedidoDeValidacao = (PedidoDeValidacao)comunicado;

                    this.usuario.receba (valideTelefone (pedidoDeValidacao.getTelefone()));
                }
                else if (comunicado instanceof PedidoParaSair)
                {
                    synchronized (this.usuarios)
                    {
                        this.usuarios.remove (this.usuario);
                    }
                    this.usuario.adeus();
                }
            }
        }
        catch (Exception erro)
        {
            try
            {
                transmissor.close ();
                receptor   .close ();
            }
            catch (Exception falha)
            {} // so tentando fechar antes de acabar a thread

            return;
        }
    }
}
