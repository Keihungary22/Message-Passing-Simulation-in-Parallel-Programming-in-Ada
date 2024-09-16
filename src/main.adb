with Ada.Text_IO, Ada.Numerics.Discrete_Random;
use Ada.Text_IO;

procedure Main is

   subtype M_Int is Integer range 0 .. 255;
   type Data_Arr is array (M_Int) of Boolean;
   subtype T_Int is Integer range 1 .. 3;

   package random_creater is new Ada.Numerics.Discrete_Random (T_Int);
   use random_creater;
   G : Generator;

   protected type CellTower is
      procedure Init(Id : in T_Int);
      entry attach( Id : in Integer; res : out Boolean);
      entry message(Id : in Integer; s : in String);
      procedure detach (Id : in Integer);
      function isAlive return Boolean;
      procedure Off;
   private
      onTower : Boolean := false;
      TID : T_Int;
   end CellTower;

   task type mobile (Id : M_Int) is
      entry Signal_Lost;
   end mobile;


   type PMobile is access all mobile;
   P : PMobile;

   protected Database is
      procedure Auth (Id : in Integer; res : out Boolean; TId : in Integer);
      function isConnected (Id : Integer) return Boolean;
      procedure Off (Id : in Integer);
   private
      Data : Data_Arr;
   end Database;

   --  type PTower is access CellTower;
   type T_Arr is array (T_Int) of CellTower;
   T : T_Arr;

   task type checkCondition (TID : Integer; mob : Pmobile);

   type PC is access checkCondition;


   task body checkCondition is
   begin
      delay 1.0;
      if not T (TID).isAlive then
         mob.Signal_Lost;
      end if;
   end checkCondition;


   protected body Database is
      procedure Auth (Id : in Integer; res : out Boolean; TId : in Integer) is
      begin
         if (Id <= 100 and TId = 1) or (Id <= 200 and Id > 100 and TId = 2) or (Id > 200 and TId = 3) then
            Data (Id) := true;
            res := true;
         else
            Put_Line ("D: fount a contradict between Id("& Integer'Image(Id)& ")and TId(" &Integer'Image(TId)&").");
            res := false;
         end if;
      end Auth;

      function isConnected (Id : Integer) return Boolean is
      begin
         return Data(Id);
      end isConnected;

      procedure Off (Id : in Integer) is
      begin
         Data (Id) := false;
      end Off;
   end Database;


   task body mobile is
      cond : Boolean;
      Tower : T_Int;
      cond2 : Boolean;
      tester : PC;
      this : Pmobile := mobile'Unchecked_Access;
   begin
      Reset(G);
      Tower := Random(G);
      delay 0.5;
      Put_Line ("M" & Integer'Image (Id) & ": try to connect.");
      T(Tower).attach (Id, cond);
      if cond then
         cond2 := cond;
         while cond2 loop
            tester := new checkCondition (Tower, this);
            select
               accept Signal_Lost do
                  cond2 := false;
                  Put_Line("lost signal");
               end Signal_Lost;
            or
               delay 0.5;
               Put_Line ("M" & Integer'Image (Id) & ": connected successfully and will send 'Hello'.");
               if T(Tower).isAlive then
                  T (Tower).message (Id, "Hello");
                  Put_Line(Boolean'Image(T(Tower).isAlive));
               end if;
               delay 0.5;
            end select;
         end loop;
         Put_Line ("M" & Integer'Image (Id) & ": successfully disconnected.");
         T (Tower).detach (Id);

      else
         Put_Line ("M" & Integer'Image (Id) & ": failed to connect.");
      end if;
   end mobile;


   protected body CellTower is
      procedure Init(Id : in T_Int) is
      begin
         onTower := true;
         TID := Id;
      end Init;

      entry attach ( Id : in Integer; res : out Boolean) when onTower is
      begin
         Database.Auth (Id, res, TID);
         if res then
            res := true;
            Put_Line ("T: mobile" & Integer'Image (Id) & " successfully connected.");
         else
            Put_Line ("T: mobile" & Integer'Image (Id) & " failed to connect.");
         end if;
      end attach;

      entry message (Id : in Integer; s : in String) when onTower is
      begin
         if Database.isConnected(Id) then
            Put_Line ("T: mobile" & Integer'Image (Id) & " received message " & s);
         else
            Put_Line ("T: mobile" & Integer'Image (Id) & " is not connected.");
         end if;
      end message;

      procedure detach (Id : in Integer) is
      begin
         Database.Off(Id);
         Put_Line("T: mobile" & Integer'Image(Id) & " successfully disconnected.");
      end detach;

      function isAlive return Boolean is
      begin
         return onTower;
      end isAlive;

      procedure Off is
      begin
         onTower := false;
      end Off;

   end CellTower;


begin

   for i in T'range loop
      T (i).Init(i);
   end loop;

   for i in 1 .. 8 loop
      delay 0.5;
      P := new mobile (i * 30);
   end loop;

   delay 5.0;
   for i in T'range loop
      T (i).Off;
   end loop;

end Main;
