using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;

namespace Listen1Launcher
{
    // Root-directory launcher for the portable layout:
    //   Listen1.exe        (this launcher)
    //   portable           (flag file)
    //   Program/Listen1.exe (real Electron app)
    //   Data/              (user data)
    internal static class Program
    {
        private static int Main()
        {
            string root = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
            string appPath = Path.Combine(root, "Program", "Listen1.exe");
            if (!File.Exists(appPath))
            {
                Console.Error.WriteLine("Listen1 program not found: " + appPath);
                return 1;
            }

            var startInfo = new ProcessStartInfo
            {
                FileName = appPath,
                WorkingDirectory = Path.Combine(root, "Program"),
                Arguments = "--listen1-portable \"" + root + "\"",
                UseShellExecute = false,
            };

            try
            {
                Process.Start(startInfo);
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine("Failed to start Listen1: " + ex.Message);
                return 1;
            }
            return 0;
        }
    }
}
