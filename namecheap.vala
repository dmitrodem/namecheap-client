public errordomain NamecheapError {
	NETIFERROR,
	CLIENTERROR
}

public class NamecheapClient : GLib.Object {

	const string URI = "https://dynamicdns.park-your-domain.com/update";

	public string host {get; set;}
	public string domain {get; set;}
	public string secret {get; set;}
	public string iface {get; set;}
	public string ip {get; set;}

	public bool debug {get; set;}

	public NamecheapClient.env() {
		var envp = GLib.Environ.get();
		this.host	= GLib.Environ.get_variable(envp, "NAMECHEAP_HOST");
		this.domain = GLib.Environ.get_variable(envp, "NAMECHEAP_DOMAIN");
		this.secret = GLib.Environ.get_variable(envp, "NAMECHEAP_SECRET");
		this.iface  = GLib.Environ.get_variable(envp, "NAMECHEAP_IFACE");
	}

	public static string get_ipv4_address(string? iface) throws NamecheapError {
		if (iface == null) {
			throw new NamecheapError.NETIFERROR("Empty interface name");
		}
		var fd = Posix.socket(Posix.AF_INET, Posix.SOCK_DGRAM, Posix.IPProto.IP);
		if (fd == -1) {
			throw new NamecheapError.NETIFERROR("Cannot open socket");
		}
		var req = Linux.Network.IfReq();
		req.ifr_addr.sa_family = Posix.AF_INET;
		req.ifr_name = (char []) (iface.data);

		var r = Posix.ioctl(fd, Linux.Network.SIOCGIFADDR, &req);
		if (r == -1) {
			throw new NamecheapError.NETIFERROR("ioctl failed");
		}
		Posix.close(fd);
		return Posix.inet_ntoa(((Posix.SockAddrIn *)&(req.ifr_addr))->sin_addr);
	}

	public void update() throws NamecheapError {
		var u = new Soup.URI ("https://dynamicdns.park-your-domain.com/update");
		u.set_query_from_fields("host", this.host,
								"domain", this.domain,
								"password", this.secret,
								"ip", this.ip);
		var uri = u.to_string(false);
		if (this.debug) {
			printerr("URI = %s\n", uri);
		}
		var message = new Soup.Message("GET", uri);
		var session = new Soup.Session();
		session.send_message(message);
		if (message.status_code != 200) {
			throw new NamecheapError.CLIENTERROR("No reply from namecheap");
		}
		var text = ((string)message.response_body.data).replace("utf-16", "utf-8");
		if (this.debug) {
			printerr("Reply = \"%s\"\n", text);
		}
		Xml.Doc *doc = Xml.Parser.parse_memory(text, text.length);
		if (doc == null) {
			throw new NamecheapError.CLIENTERROR("Cannot parse response from namecheap");
		}
		var root = doc->get_root_element();
		if (root == null) {
			throw new NamecheapError.CLIENTERROR("Failed to get root node from responce");
		}
		if (root->name != "interface-response") {
			throw new NamecheapError.CLIENTERROR("Root node is not interface-response");
		}
		bool ok = false;
		for (var iter = root->children; iter != null;  iter = iter->next) {
			if ((iter->type == Xml.ElementType.ELEMENT_NODE) &&
				(iter->name == "ErrCount") &&
				(iter->get_content() == "0")) {
				ok = true;
			}
		}
		if (!ok) {
			throw new NamecheapError.CLIENTERROR("Namecheap replied with error");
		}
	}

	private static string opt_host = null;
	private static string opt_domain = null;
	private static string opt_secret = null;
	private static string opt_iface = null;
	private static string opt_ip = null;
	private static bool opt_debug = false;
	private const OptionEntry[] options = {
		{"host"		, '\0', OptionFlags.NONE, OptionArg.STRING, ref opt_host, "Host name", "HOST"},
		{"domain"	, '\0', OptionFlags.NONE, OptionArg.STRING, ref opt_domain, "Domain name", "DOMAIN"},
		{"secret"	, '\0', OptionFlags.NONE, OptionArg.STRING, ref opt_secret, "Namecheap API key", "SECRET"},
		{"iface"	, '\0', OptionFlags.NONE, OptionArg.STRING, ref opt_iface, "Network interface name", "IFACE"},
		{"ip"		, '\0', OptionFlags.NONE, OptionArg.STRING, ref opt_ip, "IP address", "IP"},
		{"debug"	, '\0', OptionFlags.NONE, OptionArg.NONE,   ref opt_debug, "Debug request", null},
		{null}
	};
	public static int main(string[] argv) {
		try {
			var opt_context = new OptionContext ("- Namecheap client");
			opt_context.set_help_enabled (true);
			opt_context.add_main_entries (options, null);
			opt_context.parse (ref argv);
		} catch (OptionError e) {
			printerr ("error: %s\n", e.message);
			printerr ("Run '%s --help' to see a full list of available command line options.\n", argv[0]);
			return Posix.EXIT_FAILURE;
		}

		var client = new NamecheapClient.env();
		client.debug = opt_debug;
		if (opt_host != null) {
			client.host = opt_host;
		}
		if (opt_domain != null) {
			client.domain = opt_domain;
		}
		if (opt_secret != null) {
			client.secret = opt_secret;
		}
		if (opt_iface != null) {
			client.iface = opt_iface;
		}
		try {
			if (opt_ip != null) {
				client.ip = opt_ip;
			} else {
				client.ip = get_ipv4_address(client.iface);
			}
			client.update();
		} catch (NamecheapError e) {
			print(@"Failed to update ip, $(e.message)");
			return Posix.EXIT_FAILURE;
		}
		print("Done\n");
		return Posix.EXIT_SUCCESS;
	}
}