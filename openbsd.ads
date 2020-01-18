-- OpenBSD - Provide high-level Ada interfaces to OpenBSD's pledge and unveil.
-- Written in 2019 by Prince Trippy programmer@verisimilitudes.net .

-- To the extent possible under law, the author(s) have dedicated all copyright and related and
-- neighboring rights to this software to the public domain worldwide.
-- This software is distributed without any warranty.

-- You should have received a copy of the CC0 Public Domain Dedication along with this software.
-- If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

-- This is consistent with OpenBSD 6.5.

package OpenBSD is
   type Allowing is (Allowed, Disallowed);
   type Promise is (Stdio, Rpath, Wpath, Cpath, Dpath, Tmppath, Inet, Mcast, Fattr, Chown, Flock,
                    Unix, Dns, Getpw, Sendfd, Recvfd, Tape, Tty, Proc, Exec, Prot_Exec, Settime,
                    Ps, Vminfo, Id, Pf, Audio, Video, Bpf, Unveil, Error);
   type Promise_Array is array (Promise) of Allowing;
   Pledge_Error : exception;
   procedure Pledge (Promises : in Promise_Array);

   type Permission is (Read, Write, Execute, Create);
   type Permission_Array is array (Permission) of Allowing;
   Unveil_Error : exception;
   procedure Unveil (Path : in String; Permissions : in Permission_Array);
   -- Perhaps I should also have a Disable_Unveil or is Pledge sufficient for all such cases?
end OpenBSD;
