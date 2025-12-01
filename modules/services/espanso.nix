{
  flake.modules.homeManager.espanso = {
    pkgs,
    lib,
    ...
  }: {
    # text expander functionality (but open source donationware, x-platform, rust-based)
    services.espanso = {
      enable = true;
      package = pkgs.stable.espanso;
      configs = {
        default = {
          #search_shortcut = "off";
          search_shortcut = "ALT+SHIFT+SPACE";
          search_trigger = "off"; # could allow typing .shortcut to trigger menu (or whatever you specify)
        };
      };
      matches = {
        base = {
          matches = [
            {
              trigger = "lorem1";
              replace = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua";
            }
            {
              trigger = "lorem2";
              replace = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.";
            }
            {
              trigger = "lorem3";
              replace = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.";
            }
            {
              trigger = "icphone";
              replace = "415.968.9607";
            }
            {
              trigger = ":checkbox:";
              replace = "⬜️";
            }
            {
              trigger = ":checked:";
              replace = "✅";
            }
            {
              trigger = ":checkmark:";
              replace = "✓";
            }
            {
              trigger = "acmlink";
              replace = "https://dl.acm.org/citation.cfm?id=3201602";
            }
            {
              trigger = "icaddr1";
              replace = "1750 30th Street #500";
            }
            {
              trigger = "icaddr2";
              replace = "Boulder, CO 80301-1029";
            }
            {
              trigger = "icoffice1";
              replace = "1919 14th Street, 7th Floor";
            }
            {
              trigger = "icoffice2";
              replace = "Boulder, CO 80302";
            }
            {
              trigger = "..p";
              replace = "..Patrick";
            }
            {
              trigger = "myskype";
              replace = "303.731.3155";
            }
            {
              trigger = "-icc";
              replace = "ironcorelabs.com";
            }
            {
              trigger = "--icl";
              replace = "IronCore Labs";
            }
            {
              trigger = ".zsg";
              replace = ".zmre@spamgourmet.com";
            }
            {
              trigger = "gbot";
              replace = "Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Googlebot/2.1; +http://www.google.com/bot.html) Chrome/127.0.6533.72 Safari/537.36";
            }
            {
              trigger = "gbnews";
              replace = "Googlebot-News";
            }
            {
              trigger = "bbot";
              replace = "Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)";
            }
            {
              trigger = "mycal";
              replace = "https://app.hubspot.com/meetings/patrick-walsh";
            }
            {
              trigger = "p@i";
              replace = "patrick.walsh@ironcorelabs.com";
            }
            {
              trigger = "p@w";
              replace = "pwalsh@well.com";
            }
            {
              trigger = "p@m";
              replace = "pwalsh@mistgate.org";
            }
            {
              trigger = "p@g";
              replace = "pjwalsh@gmail.com";
            }
            # {
            #   trigger = "--sig";
            #   replace = ''
            #     --
            #     Patrick Walsh  ●  CEO
            #     patrick.walsh@ironcorelabs.com  ●  @zmre
            #
            #     IronCore Labs
            #     Strategic privacy for modern SaaS.
            #     https://ironcorelabs.com  ●  @ironcorelabs  ●  415.968.9607
            #   '';
            # }
            {
              trigger = "--sig";
              html = ''
                <p>--&nbsp;</p>
                <p style="font-family:Helvetica,Arial,sans-serif;font-size:14px;"><b>Patrick Walsh</b>&nbsp;&nbsp;<span style="color:red;">&bull;</span>&nbsp;&nbsp;Co-founder and CEO<br/>
                patrick.walsh@ironcorelabs.com&nbsp;&nbsp;<span style="color:red;">&bull;</span>&nbsp;&nbsp;@zmre<br/>
                <br/>
                <b>IronCore Labs</b><br/>
                Real data protection for cloud apps and AI<br/>
                <a href="https://ironcorelabs.com/">ironcorelabs.com</a>&nbsp;&nbsp;<span style="color:red;">&bull;</span>&nbsp;&nbsp;@ironcorelabs&nbsp;&nbsp;<span style="color:red;">&bull;</span>&nbsp;&nbsp;415.968.9607<br/>
                </p>
                <p style="font-family:Helvetica,Arial,sans-serif;font-size:14px;color:red;">Sign up for <a style="color:red;font-weight:bold;" href="https://ironcorelabs.com/products/cloaked-ai/">Cloaked AI</a> to protect your AI data</p>
              '';
            }
            {
              trigger = "vcintroreply";
              form = ''
                Thanks, [[introducer]]! (To bcc.)

                Hi [[investor]],

                Nice to meet you and thanks for your interest in talking with us. I'd love to take you through our pitch.  What are some good times for you?  Or alternatively, if you'd prefer, you can grab some time on my calendar directly here: https://app.hubspot.com/meetings/patrick-walsh

                Thanks and I look forward to talking with you soon.

                Regards,

                ..Patrick
              '';
            }
            {
              trigger = "vcintrorequest";
              vars = [
                {
                  name = "form";
                  type = "form";
                  params = {
                    layout = ''
                      Introducer: [[introducer]]
                      Investor: [[investor]]
                      VC Firm: [[firm]]
                      Reason for them: [[reason]]
                      Round size: [[roundsize]]
                      ARR: [[arr]]
                    '';
                    fields = {
                      introducer = {multiline = false;};
                      investor = {multiline = false;};
                      firm = {multiline = false;};
                      reason = {multiline = true;};
                      roundsize = {multiline = false;};
                      arr = {mulitline = false;};
                    };
                  };
                }
              ];
              html = ''
                <p>{{form.introducer}}, thanks for offering to introduce us.</p>

                <p>Hi {{form.investor}},</p>

                <p>I'm hoping you're the right person to talk to at {{form.firm}} and that we're a potential fit -- {{form.reason}}</p>

                <p>Here's the quick rundown on IronCore Labs:</p>

                <p><b>Problem:</b></p>

                <p>Today, over half of GenAI projects aren't making it to production because of privacy and security issues (per Gartner). Major companies like Google and Facebook are unable to release new products (ie, Bard and Threads) in the EU because of data privacy issues. But the problem isn't constrained to the EU. 60% of CEOs globally say privacy and security issues are blocking their adoption of new AI capabilities.</p>

                <p><b>Solution:</b></p>

                <p>With our Cloaked AI product, companies can use the latest and best hosted cloud solutions for working with GenAI without leaking their private and confidential data (or their customers'). They can search, chat, prevent hallucinations, leverage facial recognition, and more without any risk to the data involved.</p>

                <p>IronCore <b>unlocks the most valuable AI use cases by freeing companies from the privacy and security issues</b> that are blocking them.</p>

                <p>We're currently raising our Series A. Here are the key details:</p>

                <ul>
                <li><b>Broad Categories:</b> Cybersecurity, Artificial Intelligence, Data Protection, Developer and DevOps Tools, Enterprise</li>
                <li><b>Company progress:</b> ~{{form.progress}}M in ARR with large marquee customers like HubSpot and Zendesk</li>
                <li><b>Round size:</b> {{form.roundsize}}M</li>
                <li><b>AI product readiness:</b> Cloaked AI is currently in beta</li>
                </ul>

                <p>And if that's not enough to get you started, we have a two minute video that's a mini version of our pitch:</p>

                <p>https://docsend.com/view/q6535e3wn65yqiai</p>

                <p>Regards,</p>

                <p>..Patrick</p>
              '';
            }
            {
              # Dates
              trigger = "ddate";
              replace = "{{mydate}}";
              vars = [
                {
                  name = "mydate";
                  type = "date";
                  params = {format = "%Y-%m-%d";};
                }
              ];
            }
            {
              # Shell commands example
              trigger = ":shell";
              replace = "{{output}}";
              vars = [
                {
                  name = "output";
                  type = "shell";
                  params = {cmd = "echo Hello from your shell";};
                }
              ];
            }
          ];
        };
      };
    };
  };
}
