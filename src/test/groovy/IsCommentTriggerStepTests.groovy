import com.lesfurets.jenkins.unit.BasePipelineTest
import org.junit.Before
import org.junit.Test
import static com.lesfurets.jenkins.unit.MethodCall.callArgsToString
import static org.junit.Assert.assertTrue
import static org.junit.Assert.assertFalse


class IsCommentTriggerStepTests extends BasePipelineTest {
  Map env = [:]

  @Override
  @Before
  void setUp() throws Exception {
    super.setUp()

    env.WORKSPACE = "WS"
    binding.setVariable('env', env)
    helper.registerAllowedMethod("log", [Map.class], {m -> println m.text})
    helper.registerAllowedMethod("getGithubToken", {return 'TOKEN'})
    helper.registerAllowedMethod("githubApiCall", [Map.class], {return [login: 'user', company: '@elastic']})
  }

  @Test
  void test() throws Exception {
    binding.getVariable('currentBuild').getBuildCauses = {
      return [
        [
          _class: 'org.jenkinsci.plugins.pipeline.github.trigger.IssueCommentCause',
          shortDescription: 'Started by a comment',
          userLogin: 'admin',
        ]
      ]
    }
    def script = loadScript("vars/isCommentTrigger.groovy")
    def ret = script.call()
    printCallStack()
    assertTrue(ret)
    assertTrue('admin'.equals(env.BUILD_CAUSE_USER))
    assertJobStatusSuccess()
  }

  @Test
  void testNoCommentTriggered() throws Exception {
    binding.getVariable('currentBuild').getBuildCauses = {
      return [
        [
          _class: 'hudson.model.Cause$UserIdCause',
          shortDescription: 'Started by user admin',
          userId: 'admin',
          userName: 'admin'
        ]
      ]
    }

    def script = loadScript("vars/isCommentTrigger.groovy")
    def ret = script.call()
    printCallStack()
    assertFalse(ret)
    assertJobStatusSuccess()
  }

  @Test
  void testNoElasticUser() throws Exception {
    binding.getVariable('currentBuild').getBuildCauses = {
      return [
        [
          _class: 'org.jenkinsci.plugins.pipeline.github.trigger.IssueCommentCause',
          shortDescription: 'Started by a comment',
          userLogin: 'admin',
        ]
      ]
    }
    helper.registerAllowedMethod("githubApiCall", [Map.class], {return [login: 'user', company: '@none']})
    def script = loadScript("vars/isCommentTrigger.groovy")
    def ret = script.call()
    printCallStack()
    assertFalse(ret)
    assertJobStatusSuccess()
  }
}