using System;
using System.Collections.Generic;
using System.Drawing;
using System.Windows.Forms;
using System.Drawing.Imaging;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Threading;
using System.Text;

namespace DesktopApp1 {
    public partial class Form1 : Form {
        private int alpha = 0;

        public Form1()
        {
            InitializeComponent();
        }

        private static Bitmap SetAlpha(Bitmap bmpIn, int alpha)
        {
            Bitmap bmpOut = new Bitmap(bmpIn.Width, bmpIn.Height);
            float a = alpha / 255f;
            Rectangle r = new Rectangle(0, 0, bmpIn.Width, bmpIn.Height);

            float[][] matrixItems = {
                new float[] {1, 0, 0, 0, 0},
                new float[] {0, 1, 0, 0, 0},
                new float[] {0, 0, 1, 0, 0},
                new float[] {0, 0, 0, a, 0},
                new float[] {0, 0, 0, 0, 1}
            };

            ColorMatrix colorMatrix = new ColorMatrix(matrixItems);

            ImageAttributes imageAtt = new ImageAttributes();
            imageAtt.SetColorMatrix(colorMatrix, ColorMatrixFlag.Default, ColorAdjustType.Bitmap);

            using (Graphics g = Graphics.FromImage(bmpOut))
                g.DrawImage(bmpIn, r, r.X, r.Y, r.Width, r.Height, GraphicsUnit.Pixel, imageAtt);

            return bmpOut;
        }

        private void Form1_Load(object sender, EventArgs e)
        {

            foreach (Control c in this.Controls)
            {
                // This cast should be safe, because we already know c is a PictureBox.
                if (c is PictureBox pic)
                {
                    // picture boxes all start as true.  This value is flipped to false when the form loads.
                    // image variables start as null
                    Globals.pictureStatus.Add(pic.Name, true);
                    Globals.pictureImages.Add(pic.Name, null);
                    pictureBox_Click(sender: pic, e: null);
                }
            }

            Thread ThreadingServer = new Thread(StartudpListener)
            {
                IsBackground = true
            };
            ThreadingServer.Start();
        }

        private void THREAD_MOD(string teste)
        {
            txtStatus.Text += Environment.NewLine + teste;
        }

        private void Form1_FormClosing(object sender, FormClosingEventArgs e)
        {
            Application.Exit();
        }

        private void UpdateImage(PictureBox p, bool state)
        {
            string BoxName = p.Name;

            //Update the object status
            Globals.pictureStatus[BoxName] = state;

            alpha = state ? 255 : 55;

            if (Globals.pictureImages[BoxName] == null)
            {
                Globals.pictureImages[BoxName] = (Bitmap)p.Image.Clone();
            }

            p.BackColor = Color.Transparent;
            p.Image = SetAlpha((Bitmap)Globals.pictureImages[BoxName], alpha);
        }

        private void pictureBox_Click(object sender, EventArgs e)
        {
            PictureBox p = sender as PictureBox;
            UpdateImage(p, !Globals.pictureStatus[p.Name]);
        }

        private void StartudpListener()
        {
            const int listenPort = 11000;
            UdpClient listener = new UdpClient(listenPort);
            IPEndPoint groupEP = new IPEndPoint(IPAddress.Any, listenPort);
            Action<string> DelegateTeste_ModifyText = THREAD_MOD;

            try
            {
                while (true)
                {
                    Console.WriteLine("Waiting for broadcast");
                    byte[] bytesFrom = listener.Receive(ref groupEP);
                    string dataFromClient = Encoding.ASCII.GetString(bytesFrom, 0, bytesFrom.Length);
                    dataFromClient = dataFromClient.TrimEnd('\n');

                    try
                    {
                        string[] words = dataFromClient.Split(':');
                        string tag = words[0];
                        bool state = Convert.ToInt16(words[1]) != 0;

                        foreach (var pb in this.Controls
                        .OfType<PictureBox>()
                        .Where(x => (string)x.Tag == tag)
                        .ToList())
                        {
                            UpdateImage(pb, state);
                        }

                        Console.WriteLine($"Received broadcast from {groupEP} :");
                        Console.WriteLine($" {dataFromClient}");
                        Invoke(DelegateTeste_ModifyText, dataFromClient);
                    }
                    catch
                    {
                        Console.WriteLine("Invalid input caught.");
                    }
                }
            }
            catch (SocketException e)
            {
                Console.WriteLine("Exception caught:");
                Console.WriteLine(e);
            }
            finally
            {
                listener.Close();
            }
        }

        public class Globals {
            public static Dictionary<string, bool> pictureStatus = new Dictionary<string, bool>();
            public static Dictionary<string, Image> pictureImages = new Dictionary<string, Image>();
        }
    }
}
