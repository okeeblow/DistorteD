using System;
using System.Drawing;
using System.Collections;
using System.ComponentModel;
using System.Windows.Forms;
using System.Data;

namespace CHECKING_YOU_OUT_Sharp
{
	/// <summary>
	/// Summary description for Form1.
	/// </summary>
	public class Form1 : System.Windows.Forms.Form
	{
		private System.Windows.Forms.MainMenu mainMenu1;
		private System.Windows.Forms.MenuItem menuItem1;
		private System.Windows.Forms.CheckBox CHECKING;
		private System.Windows.Forms.CheckBox YOU;
		private System.Windows.Forms.CheckBox OUT;
		/// <summary>
		/// Required designer variable.
		/// </summary>
		private System.ComponentModel.Container components = null;

		public Form1()
		{
			//
			// Required for Windows Form Designer support
			//
			InitializeComponent();

			//
			// Add any constructor code after InitializeComponent call
			//
		}

		/// <summary>
		/// Clean up any resources being used.
		/// </summary>
		protected override void Dispose( bool disposing )
		{
			if( disposing )
			{
				if (components != null) 
				{
					components.Dispose();
				}
			}
			base.Dispose( disposing );
		}

		#region Windows Form Designer generated code
		/// <summary>
		/// Required method for Designer support - do not modify
		/// the contents of this method with the code editor.
		/// </summary>
		private void InitializeComponent()
		{
			System.Resources.ResourceManager resources = new System.Resources.ResourceManager(typeof(Form1));
			this.mainMenu1 = new System.Windows.Forms.MainMenu();
			this.menuItem1 = new System.Windows.Forms.MenuItem();
			this.CHECKING = new System.Windows.Forms.CheckBox();
			this.YOU = new System.Windows.Forms.CheckBox();
			this.OUT = new System.Windows.Forms.CheckBox();
			this.SuspendLayout();
			// 
			// mainMenu1
			// 
			this.mainMenu1.MenuItems.AddRange(new System.Windows.Forms.MenuItem[] {
																					  this.menuItem1});
			// 
			// menuItem1
			// 
			this.menuItem1.Index = 0;
			this.menuItem1.Text = "COOLTRAINER dot ORG";
			// 
			// CHECKING
			// 
			this.CHECKING.Location = new System.Drawing.Point(24, 32);
			this.CHECKING.Name = "CHECKING";
			this.CHECKING.TabIndex = 0;
			this.CHECKING.Text = "CHECKING";
			this.CHECKING.CheckedChanged += new System.EventHandler(this.checkBox1_CheckedChanged);
			// 
			// YOU
			// 
			this.YOU.Location = new System.Drawing.Point(112, 120);
			this.YOU.Name = "YOU";
			this.YOU.TabIndex = 1;
			this.YOU.Text = "YOU";
			// 
			// OUT
			// 
			this.OUT.Location = new System.Drawing.Point(208, 216);
			this.OUT.Name = "OUT";
			this.OUT.TabIndex = 2;
			this.OUT.Text = "OUT";
			// 
			// Form1
			// 
			this.AutoScaleBaseSize = new System.Drawing.Size(5, 13);
			this.ClientSize = new System.Drawing.Size(325, 306);
			this.Controls.Add(this.OUT);
			this.Controls.Add(this.YOU);
			this.Controls.Add(this.CHECKING);
			this.Icon = ((System.Drawing.Icon)(resources.GetObject("$this.Icon")));
			this.Menu = this.mainMenu1;
			this.Name = "Form1";
			this.Text = "HowIsBabbyForm1";
			this.ResumeLayout(false);

		}
		#endregion

		/// <summary>
		/// The main entry point for the application.
		/// </summary>
		[STAThread]
		static void Main() 
		{
			Application.Run(new Form1());
		}

		private void checkBox1_CheckedChanged(object sender, System.EventArgs e)
		{
		
		}
	}
}
