unit Unit1;

interface

uses
  Loading,

  FMX.Controls,
  FMX.Controls.Presentation,
  FMX.Dialogs,
  FMX.Forms,
  FMX.Graphics,
  FMX.StdCtrls,
  FMX.Types,

  System.Classes,
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Variants;

type
  TProcedureExcept = reference to procedure (const AExcpetion : string);

  TForm1 = class(TForm)
    Button1: TButton;
    Label1: TLabel;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
      procedure CustomThread(
        AOnStart,                           //Procedimento de entrada      = nil
        AOnProcess,                         //Procedimento principal       = nil
        AOnComplete                : TProc; //Procedimento de finalização  = nil
        AOnError                   : TProcedureExcept = nil;
        const ADoCompleteWithError : Boolean = True
      );
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
begin
  CustomThread(
    procedure ()
    begin
      //start
      TLoading.Show('Iniciando');
    end,
    procedure ()
    var
      I: Integer;
    begin
        //process
      for I := 0 to 1000 do
      begin
        TThread.Synchronize(
          TThread.CurrentThread,
          procedure ()
          begin
            Label1.Text := Format('Processo %d de %d', [I, 100000])
          end
        );
      end;
    end,
    procedure ()
    begin
      //complete
      TLoading.Show('Finalizado');
    end,
    procedure (const AException: string)
    begin
      //excecao
    end,
    True
  );
end;

procedure TForm1.CustomThread(AOnStart, AOnProcess, AOnComplete: TProc; AOnError: TProcedureExcept;
  const ADoCompleteWithError: Boolean);
var
  LThread : TThread;
begin
  LThread :=
    TThread.CreateAnonymousThread(
      procedure()
      var
        LDoComplete : Boolean;
      begin
        try
        {$Region 'Processo completo'}
          {$Region 'Start'}
          try
            LDoComplete := True;
            //Processo Inicial
            if (Assigned(AOnStart)) then
            begin
              TThread.Synchronize(
                TThread.CurrentThread,
                procedure ()
                begin
                  AOnStart;
                end
              );
            end;
          {$EndRegion}

          {$Region 'Process'}
            //Processo Principal
            if Assigned(AOnProcess) then
              AOnProcess;
          {$EndRegion}

          except on E:Exception do
            begin
              LDoComplete := ADoCompleteWithError;
              //Processo de Erro
              if Assigned(AOnError) then
              begin
                TThread.Synchronize(
                  TThread.CurrentThread,
                  procedure ()
                  begin
                    AOnError(E.Message);
                  end
                );
              end;
            end;
          end;

        finally
          {$Region 'Complete'}
          //Processo de Finalização
          if Assigned(AOnComplete) then
          begin
            TThread.Synchronize(
              TThread.CurrentThread,
              procedure ()
              begin
                AOnComplete;
              end
            );
          end;
          {$EndRegion}
          {$EndRegion}
        end;
      end
    );

  LThread.FreeOnTerminate := True;
  LThread.Start;
end;

end.
