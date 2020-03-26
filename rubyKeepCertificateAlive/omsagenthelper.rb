module OMSAgentHelperModule

    class OnboardingHelper

        @@workspace_id = ''
        @@domain = ''
        @@certificate_update_endpoint = ''
        @@agent_uuid = ''

        # Initialize onboarding helper, If these values do not exist fail horribly
        def initialize(workspace_id, domain, agent_uuid)
            @workspace_id = workspace_id
            @domain = domain
            @certificate_update_endpoint = "https://" + workspace_id + "." + domain + "/ConfigurationService.Svc/RenewCertificate"
            @agent_uuid = agent_uuid #let's get this from certificate : more reliable?
        end

        def register_certs()
            puts @certificate_update_endpoint
        end
    end
end

# Boilerplate syntax for ruby
if __FILE__ == $0
    ret_code = 0
    maintenance = OMSAgentHelperModule::OnboardingHelper.new(
        ENV["CI_WSID"],
        ENV["CI_DOMAIN"],
        ENV["CI_AGENT_GUID"]
    )
    maintenance.register_certs()
    exit ret_code
  end