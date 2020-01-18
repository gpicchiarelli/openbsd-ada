-- OpenBSD - Provide high-level Ada interfaces to OpenBSD's pledge and unveil.
-- Written in 2019 by Prince Trippy programmer@verisimilitudes.net .

-- To the extent possible under law, the author(s) have dedicated all copyright and related and
-- neighboring rights to this software to the public domain worldwide.
-- This software is distributed without any warranty.

-- You should have received a copy of the CC0 Public Domain Dedication along with this software.
-- If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

pragma Profile(No_Implementation_Extensions);
pragma Assertion_Policy(Check);

with Interfaces.C.Strings, Ada.Strings.Maps.Constants, Ada.Strings.Bounded;
use  Interfaces.C.Strings, Interfaces.C;

package body OpenBSD is
   -- The pledge is documented as having three failure cases.
   -- EFAULT, an invalid pointer, simply won't happen.
   -- EINVAL, a malformed string, is similarly not a concern.
   -- EPERM, a permissions error, is then the only failure case left.
   -- So, having a single exception for this procedure is fine.
   function C_Pledge (Promises, Exec_Promises : Chars_Ptr) return Int
     with Import => True, Convention => C, External_Name => "pledge";

   procedure Pledge (Promises : in Promise_Array) is
      -- I'd prefer to have a bounded string only as large as necessary.
      -- It should automatically be consistent with the Promise type.
      -- How would I nicely calculate that at compilation, though?
      package B is new Ada.Strings.Bounded.Generic_Bounded_Length(178);
      use B; -- Perhaps I should use type here, instead.
      S : Bounded_String;
   begin
      for P in Promise loop
         if Promises(P) = Allowed then
            -- Perhaps I should have this avoid the unnecessary last space.
            S := S & Promise'Image(P) & ' ';
         end if;
      end loop;
      -- It seems the promises are case-sensitive.
      Translate(S, Ada.Strings.Maps.Constants.Lower_Case_Map);
      declare
         -- I need to fix this to avoid Unchecked_Access, later.
         C : aliased Char_Array := To_C(To_String(S));
         P : Chars_Ptr := To_Chars_Ptr(Char_Array_Access'(C'Unchecked_Access));
      begin
         if C_Pledge(P, Null_Ptr) /= 0 then
            raise Pledge_Error;
         end if;
      end;
   end Pledge;
   -- A precondition that the limit for bounded strings is larger than the
   -- largest possible promise string seems the best option available.
   -- A precondition such as this could likely be determined at compilation.
   -- I need to specify this precondition privately, though; how?

   -- The unveil is documented as having four failure cases.
   -- E2BIG, a storage exhaustion error, will be conflated with the others.
   -- ENOENT, an invalid directory name, is also reasonable to conflate.
   -- EINVAL, a malformed string, is not a concern.
   -- EPERM, a permissions error, is similarly conflated with the others.
   -- Having a single exception for this procedure isn't as fine as with pledge.
   -- However, it's acceptable, given each case could be determined anyway.
   function C_Unveil (Path, Permissions : Chars_Ptr) return Int
     with Import => True, Convention => C, External_Name => "unveil";

   procedure Unveil (Path : in String; Permissions : in Permission_Array) is
      -- I'd similarly prefer to have a string that is consistent here.
      -- Given the small size and whatnot, this is less of an issue, however.
      package B is new Ada.Strings.Bounded.Generic_Bounded_Length(4);
      use B; -- Perhaps I should use type here, instead.
      S : Bounded_String;
      C : constant array (Permission) of Character
        := (Read => 'r', Write => 'w', Execute => 'x', Create => 'c');
   begin
      for P in Permission loop
         if Permissions(P) = Allowed then
            S := S & C(P);
         end if;
      end loop;
      declare
         -- I need to fix this to avoid Unchecked_Access, later.
         C : aliased Char_Array := To_C(To_String(S));
         D : aliased Char_Array := To_C(Path);
         P : Chars_Ptr := To_Chars_Ptr(Char_Array_Access'(C'Unchecked_Access));
         Q : Chars_Ptr := To_Chars_Ptr(Char_Array_Access'(D'Unchecked_Access));
      begin
         if C_Unveil(Q, P) /= 0 then
            raise Unveil_Error;
         end if;
      end;
   end Unveil;
   -- I could add a precondition here, but unveil isn't subject to the same issues.
   -- The permission array of character won't compile if the enumeration is changed.
end OpenBSD;
